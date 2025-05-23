import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../services/storage_service.dart';
import '../models/usuario.dart';

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _token;
  String? _correo;
  Usuario? _usuario; // Nuevo campo para almacenar datos del usuario

  final StorageService _storageService = StorageService();

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get token => _token;
  String? get correo => _correo;
  Usuario? get usuario => _usuario; // Getter para los datos del usuario

  // Constructor que intenta recuperar datos de autenticación guardados
  AuthService() {
    _tryAutoLogin();
  }

  // Intenta iniciar sesión con datos guardados
  Future<void> _tryAutoLogin() async {
    try {
      final authData = await _storageService.getAuthData();
      if (authData != null && authData['token'] != null) {
        _token = authData['token'];
        _userId = authData['userId'];
        _correo = authData['correo'];
        
        // Cargar datos del usuario si existen
        if (authData['usuario'] != null) {
          _usuario = Usuario.fromJson(authData['usuario']);
        }
        
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      // Si hay un error, no hacemos nada (el usuario deberá iniciar sesión)
    }
  }

  // Función para extraer el ID (correo) del token JWT
  String _extractUserIdFromToken(String token) {
    try {
      // El token JWT tiene 3 partes separadas por puntos: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return _correo ?? 'unknown'; // Si no podemos decodificar, usamos el correo
      }
      
      // Decodificamos la parte del payload (segunda parte)
      String payload = parts[1];
      // Ajustamos el padding si es necesario
      payload = base64Url.normalize(payload);
      
      // Decodificamos el payload
      final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));
      
      // El JWT típicamente tiene un campo 'sub' (subject) que contiene el identificador
      return payloadMap['sub'] ?? _correo ?? 'unknown';
    } catch (e) {
      print('Error decodificando token: $e');
      return _correo ?? 'unknown';
    }
  }

  // Obtener datos del usuario desde el endpoint /docentes/yo
  Future<Usuario> _obtenerDatosUsuario() async {
    try {
      final url = '${AppConstants.apiBaseUrl}/docentes/yo';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Tiempo de espera agotado al obtener datos del usuario.');
      });

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return Usuario.fromJson(userData);
      } else if (response.statusCode == 401) {
        throw Exception('Token de acceso inválido o expirado');
      } else {
        throw Exception('Error al obtener datos del usuario (código ${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión al obtener datos del usuario: ${e.message}');
    } on FormatException catch (_) {
      throw Exception('Error en el formato de respuesta al obtener datos del usuario');
    } catch (e) {
      throw Exception('Error inesperado al obtener datos del usuario: ${e.toString()}');
    }
  }

  Future<void> login(String correo, String contrasena) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/docentes/login';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'correo': correo,
          'contrasena': contrasena,
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Tiempo de espera agotado. El servidor está tardando demasiado en responder.');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // Guardamos el token de la respuesta
        _token = responseData['access_token'];
        if (_token == null) {
          throw Exception('El token de acceso no está presente en la respuesta');
        }
        
        // Extraer el ID del usuario desde el token JWT
        _userId = _extractUserIdFromToken(_token!);
        _correo = correo;
        
        // Verificamos si es docente
        final isDoc = responseData['is_doc'] ?? false;
        if (!isDoc) {
          throw Exception('El usuario no tiene permisos de docente');
        }
        
        // Obtener datos completos del usuario
        try {
          _usuario = await _obtenerDatosUsuario();
        } catch (e) {
          // Si no podemos obtener los datos del usuario, aún permitimos el login
          // pero logueamos el error
          print('Advertencia: No se pudieron obtener los datos del usuario: $e');
          _usuario = null;
        }
        
        _isAuthenticated = true;
        
        // Guardar datos para auto-login (incluyendo datos del usuario)
        await _storageService.saveAuthData(
          _userId!, 
          _token!, 
          _correo!,
          usuario: _usuario, // Pasar los datos del usuario al storage
        );
        
        notifyListeners();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Credenciales incorrectas');
      } else if (response.statusCode == 404) {
        throw Exception('Servicio de autenticación no encontrado');
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['mensaje'] ?? errorData['message'] ?? 
                        'Error de autenticación (código ${response.statusCode})';
        } catch (e) {
          errorMessage = 'Error de autenticación (código ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    } on FormatException catch (_) {
      throw Exception('Error en el formato de respuesta del servidor');
    } on Exception catch (e) {
      throw e;  // Reenvía excepciones ya formateadas
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: ${e.toString()}');
    }
  }

  // Método para actualizar datos del usuario (útil si se necesita refrescar)
  Future<void> actualizarDatosUsuario() async {
    if (!_isAuthenticated || _token == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      _usuario = await _obtenerDatosUsuario();
      
      // Actualizar datos en storage
      await _storageService.saveAuthData(
        _userId!, 
        _token!, 
        _correo!,
        usuario: _usuario,
      );
      
      notifyListeners();
    } catch (e) {
      throw Exception('Error al actualizar datos del usuario: $e');
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _token = null;
    _correo = null;
    _usuario = null; // Limpiar datos del usuario
    
    // Eliminar datos guardados
    await _storageService.clearAuthData();
    
    notifyListeners();
  }
}