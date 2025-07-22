// lib/services/base_api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/constants.dart';
import './auth_service.dart';
import '../utils/debug_logger.dart';

abstract class BaseApiService {
  final AuthService _authService;
  
  // Cache para evitar solicitudes duplicadas
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Control de solicitudes en curso para evitar duplicados
  static final Map<String, Future<dynamic>> _ongoingRequests = {};
  
  BaseApiService(this._authService);
  
  // Obtener encabezados con autenticación para las solicitudes
  Map<String, String> get _headers {
    final token = _authService.token;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
    
    DebugLogger.info('Headers prepared: ${headers.keys.join(', ')}', tag: 'API');
    if (token != null) {
      DebugLogger.info('Token present: ${token.substring(0, 20)}...', tag: 'API');
    } else {
      DebugLogger.warning('No authentication token available', tag: 'API');
    }
    
    return headers;
  }
  
  // Método para verificar si el cache es válido
  bool _isCacheValid(String cacheKey, {int maxAgeMinutes = 5}) {
    if (!_cache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      DebugLogger.info('Cache miss for key: $cacheKey', tag: 'CACHE');
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;
    
    final isValid = difference <= maxAgeMinutes;
    DebugLogger.info('Cache ${isValid ? 'hit' : 'expired'} for key: $cacheKey (age: ${difference}min)', tag: 'CACHE');
    
    return isValid;
  }
  
  // Método para limpiar cache expirado
  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inMinutes > 30) {
        expiredKeys.add(key);
      }
    });
    
    if (expiredKeys.isNotEmpty) {
      DebugLogger.info('Cleaning ${expiredKeys.length} expired cache entries', tag: 'CACHE');
      for (final key in expiredKeys) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }
  
  // Método genérico para hacer solicitudes GET con cache
  Future<dynamic> get(String endpoint, {bool useCache = true, int cacheMinutes = 5}) async {
    final cacheKey = 'GET:$endpoint';
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    DebugLogger.api('GET', url);
    
    // Verificar cache primero
    if (useCache && _isCacheValid(cacheKey, maxAgeMinutes: cacheMinutes)) {
      DebugLogger.info('Returning cached data for: $endpoint', tag: 'CACHE');
      return _cache[cacheKey];
    }
    
    // Verificar si ya hay una solicitud en curso para este endpoint
    if (_ongoingRequests.containsKey(cacheKey)) {
      DebugLogger.info('Request already in progress for: $endpoint', tag: 'API');
      return await _ongoingRequests[cacheKey]!;
    }
    
    try {
      // Crear y almacenar el Future de la solicitud
      final requestFuture = _makeRequest(() => http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 60)));
      
      _ongoingRequests[cacheKey] = requestFuture;
      
      final result = await requestFuture;
      
      // Guardar en cache si la solicitud fue exitosa
      if (useCache) {
        DebugLogger.cache('STORE', cacheKey, data: 'Data cached successfully');
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        _cleanExpiredCache();
      }
      
      return result;
    } catch (e) {
      DebugLogger.error('GET request failed for: $endpoint', tag: 'API', error: e);
      rethrow;
    } finally {
      // Remover de solicitudes en curso
      _ongoingRequests.remove(cacheKey);
    }
  }
  
  // Método genérico para hacer solicitudes POST
  Future<dynamic> post(String endpoint, dynamic data, {bool invalidateCache = true}) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    // Convertir data a Map<String, dynamic> para el log
    Map<String, dynamic>? logData;
    if (data is Map<String, dynamic>) {
      logData = data;
    } else if (data is Map) {
      logData = Map<String, dynamic>.from(data);
    } else {
      logData = {'data': data.toString()};
    }
    
    DebugLogger.api('POST', url, body: logData);
    
    try {
      final result = await _makeRequest(() => http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 60)));
      
      // Invalidar cache relacionado después de POST exitoso
      if (invalidateCache) {
        _invalidateRelatedCache(endpoint);
      }
      
      DebugLogger.info('POST request successful for: $endpoint', tag: 'API');
      return result;
    } catch (e) {
      DebugLogger.error('POST request failed for: $endpoint', tag: 'API', error: e);
      rethrow;
    }
  }
  
  // Método genérico para hacer solicitudes PUT
  Future<dynamic> put(String endpoint, dynamic data, {bool invalidateCache = true}) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    // Convertir data a Map<String, dynamic> para el log
    Map<String, dynamic>? logData;
    if (data is Map<String, dynamic>) {
      logData = data;
    } else if (data is Map) {
      logData = Map<String, dynamic>.from(data);
    } else {
      logData = {'data': data.toString()};
    }
    
    DebugLogger.api('PUT', url, body: logData);
    
    try {
      final result = await _makeRequest(() => http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 60)));
      
      if (invalidateCache) {
        _invalidateRelatedCache(endpoint);
      }
      
      DebugLogger.info('PUT request successful for: $endpoint', tag: 'API');
      return result;
    } catch (e) {
      DebugLogger.error('PUT request failed for: $endpoint', tag: 'API', error: e);
      rethrow;
    }
  }
  
  // Método genérico para hacer solicitudes DELETE
  Future<dynamic> delete(String endpoint, {bool invalidateCache = true}) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    DebugLogger.api('DELETE', url);
    
    try {
      final result = await _makeRequest(() => http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 60)));
      
      if (invalidateCache) {
        _invalidateRelatedCache(endpoint);
      }
      
      DebugLogger.info('DELETE request successful for: $endpoint', tag: 'API');
      return result;
    } catch (e) {
      DebugLogger.error('DELETE request failed for: $endpoint', tag: 'API', error: e);
      rethrow;
    }
  }
  
  // Método común para hacer la solicitud y procesar respuesta
  Future<dynamic> _makeRequest(Future<http.Response> Function() requestFunction) async {
    try {
      DebugLogger.info('Making HTTP request...', tag: 'API');
      final response = await requestFunction();
      DebugLogger.apiResponse(response.statusCode, response.request?.url.toString() ?? 'unknown');
      return _processResponse(response);
    } catch (e) {
      DebugLogger.error('HTTP request failed', tag: 'API', error: e);
      _handleError(e);
    }
  }
  
  // Invalidar cache relacionado con un endpoint
  void _invalidateRelatedCache(String endpoint) {
    final keysToRemove = <String>[];
    
    _cache.keys.forEach((key) {
      if (key.contains('GET:') && key.contains(_extractResourceFromEndpoint(endpoint))) {
        keysToRemove.add(key);
      }
    });
    
    if (keysToRemove.isNotEmpty) {
      DebugLogger.info('Invalidating ${keysToRemove.length} cache entries for: $endpoint', tag: 'CACHE');
      for (final key in keysToRemove) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }
  
  // Extraer recurso del endpoint para invalidación de cache
  String _extractResourceFromEndpoint(String endpoint) {
    final parts = endpoint.split('/');
    if (parts.length >= 2) {
      return parts[1];
    }
    return endpoint;
  }
  
  // Método público para limpiar todo el cache
  static void clearCache() {
    DebugLogger.info('Clearing all cache', tag: 'CACHE');
    _cache.clear();
    _cacheTimestamps.clear();
    _ongoingRequests.clear();
  }
  
  // Método público para limpiar cache específico
  static void clearCacheForResource(String resource) {
    final keysToRemove = <String>[];
    
    _cache.keys.forEach((key) {
      if (key.contains(resource)) {
        keysToRemove.add(key);
      }
    });
    
    DebugLogger.info('Clearing cache for resource: $resource (${keysToRemove.length} entries)', tag: 'CACHE');
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
  
  // Procesar respuesta HTTP
  dynamic _processResponse(http.Response response) {
    DebugLogger.info('Processing response with status: ${response.statusCode}', tag: 'API');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        DebugLogger.info('Response body is empty, returning empty map', tag: 'API');
        return {};
      }
      
      try {
        final decoded = json.decode(response.body);
        DebugLogger.info('Response decoded successfully', tag: 'API');
        return decoded;
      } catch (e) {
        DebugLogger.error('Failed to decode JSON response', tag: 'API', error: e);
        DebugLogger.error('Raw response body: ${response.body}', tag: 'API');
        throw Exception('Respuesta inválida del servidor');
      }
    } else if (response.statusCode == 401) {
      DebugLogger.warning('Authentication failed (401), logging out user', tag: 'API');
      _authService.logout();
      throw Exception('Sesión expirada');
    } else {
      final message = _extractErrorMessage(response);
      DebugLogger.error('HTTP error ${response.statusCode}: $message', tag: 'API');
      throw Exception(message);
    }
  }
  
  // Extraer mensaje de error más conciso
  String _extractErrorMessage(http.Response response) {
    DebugLogger.info('Extracting error message from response: ${response.statusCode}', tag: 'API');
    
    try {
      final data = json.decode(response.body);
      DebugLogger.info('Error response decoded: $data', tag: 'API');
      
      if (data is Map && data.containsKey('detail')) {
        if (data['detail'] is List) {
          final errors = data['detail'] as List;
          return errors.isNotEmpty ? errors.first['msg'] ?? 'Error de validación' : 'Error de validación';
        } else if (data['detail'] is String) {
          return data['detail'];
        }
      }
      
      return data['mensaje'] ?? data['message'] ?? 'Error en la solicitud';
    } catch (e) {
      DebugLogger.warning('Could not decode error response, using status code', tag: 'API');
      
      switch (response.statusCode) {
        case 400:
          return 'Datos inválidos';
        case 403:
          return 'Acceso denegado';
        case 404:
          return 'Recurso no encontrado';
        case 500:
          return 'Error del servidor';
        case 502:
          return 'Servidor no disponible';
        case 503:
          return 'Servicio temporalmente no disponible';
        default:
          return 'Error de conexión (${response.statusCode})';
      }
    }
  }
  
  // Manejar errores de red
  void _handleError(dynamic error) {
    String message = 'Error de conexión';
    
    DebugLogger.error('Handling network error', tag: 'API', error: error);
    
    if (error is Exception) {
      final errorStr = error.toString();
      
      if (errorStr.contains('SocketException')) {
        message = 'Sin conexión a internet';
      } else if (errorStr.contains('timeout') || errorStr.contains('TimeoutException')) {
        message = 'Tiempo de espera agotado';
      } else if (errorStr.contains('FormatException')) {
        message = 'Respuesta inválida del servidor';
      } else if (errorStr.contains('HandshakeException')) {
        message = 'Error de seguridad SSL';
      } else {
        message = errorStr.replaceFirst('Exception: ', '');
      }
    }
    
    DebugLogger.error('Final error message: $message', tag: 'API');
    throw Exception(message);
  }
}