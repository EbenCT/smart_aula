// lib/services/base_api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/constants.dart';
import './auth_service.dart';

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
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
  
  // Método para verificar si el cache es válido
  bool _isCacheValid(String cacheKey, {int maxAgeMinutes = 5}) {
    if (!_cache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;
    
    return difference <= maxAgeMinutes;
  }
  
  // Método para limpiar cache expirado
  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inMinutes > 30) { // Cache expira después de 30 minutos
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
  
  // Método genérico para hacer solicitudes GET con cache
  Future<dynamic> get(String endpoint, {bool useCache = true, int cacheMinutes = 5}) async {
    final cacheKey = 'GET:$endpoint';
    
    // Verificar cache primero
    if (useCache && _isCacheValid(cacheKey, maxAgeMinutes: cacheMinutes)) {
      return _cache[cacheKey];
    }
    
    // Verificar si ya hay una solicitud en curso para este endpoint
    if (_ongoingRequests.containsKey(cacheKey)) {
      return await _ongoingRequests[cacheKey]!;
    }
    
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    try {
      // Crear y almacenar el Future de la solicitud
      final requestFuture = _makeRequest(() => http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 30))); // Aumentado de 15 a 30 segundos
      
      _ongoingRequests[cacheKey] = requestFuture;
      
      final result = await requestFuture;
      
      // Guardar en cache si la solicitud fue exitosa
      if (useCache) {
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        _cleanExpiredCache();
      }
      
      return result;
    } finally {
      // Remover de solicitudes en curso
      _ongoingRequests.remove(cacheKey);
    }
  }
  
  // Método genérico para hacer solicitudes POST
  Future<dynamic> post(String endpoint, dynamic data, {bool invalidateCache = true}) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    try {
      final result = await _makeRequest(() => http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 45))); // Aumentado para operaciones de escritura
      
      // Invalidar cache relacionado después de POST exitoso
      if (invalidateCache) {
        _invalidateRelatedCache(endpoint);
      }
      
      return result;
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes PUT
  Future<dynamic> put(String endpoint, dynamic data, {bool invalidateCache = true}) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    try {
      final result = await _makeRequest(() => http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 45)));
      
      if (invalidateCache) {
        _invalidateRelatedCache(endpoint);
      }
      
      return result;
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes DELETE
  Future<dynamic> delete(String endpoint, {bool invalidateCache = true}) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    
    try {
      final result = await _makeRequest(() => http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 30)));
      
      if (invalidateCache) {
        _invalidateRelatedCache(endpoint);
      }
      
      return result;
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método común para hacer la solicitud y procesar respuesta
  Future<dynamic> _makeRequest(Future<http.Response> Function() requestFunction) async {
    try {
      final response = await requestFunction();
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Invalidar cache relacionado con un endpoint
  void _invalidateRelatedCache(String endpoint) {
    final keysToRemove = <String>[];
    
    _cache.keys.forEach((key) {
      // Remover cache que contenga partes del endpoint
      if (key.contains('GET:') && key.contains(_extractResourceFromEndpoint(endpoint))) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
  
  // Extraer recurso del endpoint para invalidación de cache
  String _extractResourceFromEndpoint(String endpoint) {
    final parts = endpoint.split('/');
    if (parts.length >= 2) {
      return parts[1]; // Retorna el primer segmento después de '/'
    }
    return endpoint;
  }
  
  // Método público para limpiar todo el cache
  static void clearCache() {
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
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
  
  // Procesar respuesta HTTP
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Si la respuesta está vacía, retornamos un mapa vacío
      if (response.body.isEmpty) {
        return {};
      }
      
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expirado o no válido, deslogueamos al usuario
      _authService.logout();
      throw Exception('Sesión expirada');
    } else {
      String message = _extractErrorMessage(response);
      throw Exception(message);
    }
  }
  
  // Extraer mensaje de error más conciso
  String _extractErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      
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
      // Mensajes de error más concisos basados en código de estado
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
        // Extraer solo el mensaje sin el prefijo "Exception:"
        message = errorStr.replaceFirst('Exception: ', '');
      }
    }
    
    throw Exception(message);
  }
}