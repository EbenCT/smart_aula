// lib/services/base_api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/constants.dart';
import './auth_service.dart';

abstract class BaseApiService {
  final AuthService _authService;
  
  BaseApiService(this._authService);
  
  // Obtener encabezados con autenticación para las solicitudes
  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
  
  // Método genérico para hacer solicitudes GET
  Future<dynamic> get(String endpoint) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes POST
  Future<dynamic> post(String endpoint, dynamic data) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes PUT
  Future<dynamic> put(String endpoint, dynamic data) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes DELETE
  Future<dynamic> delete(String endpoint) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
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
      throw Exception('Sesión expirada. Por favor, inicie sesión nuevamente.');
    } else {
      String message;
      try {
        final data = json.decode(response.body);
        
        // Manejar errores de validación de FastAPI
        if (data is Map && data.containsKey('detail')) {
          if (data['detail'] is List) {
            // Error de validación con múltiples campos
            final errors = data['detail'] as List;
            message = errors.map((e) => e['msg'] ?? 'Error de validación').join(', ');
          } else if (data['detail'] is String) {
            // Error simple con mensaje string
            message = data['detail'];
          } else {
            message = 'Error en la solicitud';
          }
        } else {
          message = data['mensaje'] ?? data['message'] ?? 'Error en la solicitud';
        }
      } catch (e) {
        message = 'Error en la solicitud: ${response.statusCode}';
      }
      
      throw Exception(message);
    }
  }
  
  // Manejar errores de red
  void _handleError(dynamic error) {
    String message = 'Error de conexión';
    
    if (error is Exception) {
      message = error.toString();
    }
    
    // Errores comunes
    if (message.contains('SocketException')) {
      message = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    } else if (message.contains('timeout')) {
      message = 'La conexión al servidor ha tardado demasiado. Inténtalo más tarde.';
    }
    
    throw Exception(message);
  }
}