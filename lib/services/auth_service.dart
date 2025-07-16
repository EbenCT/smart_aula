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
  String? _userType; // Nuevo campo para tipo de usuario
  Usuario? _usuario;

  final StorageService _storageService = StorageService();

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get token => _token;
  String? get correo => _correo;
  String? get userType => _userType; // Getter para tipo de usuario
  Usuario? get usuario => _usuario;

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
        _userType = authData['userType']; // Recuperar tipo de usuario
        
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

  // Función para extraer el ID del token JWT
  String _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return _correo ?? 'unknown';
      }
      
      String payload = parts[1];
      payload = base64Url.normalize(payload);
      
      final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));
      
      return payloadMap['sub'] ?? _correo ?? 'unknown';
    } catch (e) {
      print('Error decodificando token: $e');
      return _correo ?? 'unknown';
    }
  }

  // Obtener datos del usuario según su tipo
  Future<Usuario?> _obtenerDatosUsuario() async {
    if (_userType == null) return null;
    
    try {
      String endpoint;
      
      // Determinar endpoint según tipo de usuario
      switch (_userType) {
        case 'admin':
        case 'docente':
          endpoint = '/docentes/yo';
          break;
        case 'estudiante':
          endpoint = '/estudiantes/perfil'; // Asumiendo que existe este endpoint
          break;
        case 'padre':
          endpoint = '/padres/perfil'; // Asumiendo que existe este endpoint
          break;
        default:
          return null;
      }
      
      final url = '${AppConstants.apiBaseUrl}$endpoint';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Usuario.fromJson(responseData);
      } else {
        throw Exception('Error al obtener datos del usuario');
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  // Método de login modificado para usar el nuevo endpoint
  Future<void> login(String correo, String contrasena) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/auth/login'; // Nuevo endpoint
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'correo': correo,
          'contrasena': contrasena,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        _token = responseData['access_token'];
        _userId = responseData['user_id']?.toString();
        _userType = responseData['user_type']; // Obtener tipo de usuario
        _correo = correo;
        
        // Obtener datos completos del usuario si es necesario
        if (_userType == 'admin' || _userType == 'docente') {
          try {
            _usuario = await _obtenerDatosUsuario();
          } catch (e) {
            print('Advertencia: No se pudieron obtener los datos del usuario: $e');
            _usuario = null;
          }
        }
        
        _isAuthenticated = true;
        
        // Guardar datos incluyendo el tipo de usuario
        await _storageService.saveAuthData(
          _userId!, 
          _token!, 
          _correo!,
          userType: _userType, // Guardar tipo de usuario
          usuario: _usuario,
        );
        
        notifyListeners();
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales incorrectas');
      } else if (response.statusCode == 404) {
        throw Exception('Servicio de autenticación no encontrado');
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? 
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
      throw e;
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: ${e.toString()}');
    }
  }

  // Método para actualizar datos del usuario
  Future<void> actualizarDatosUsuario() async {
    if (!_isAuthenticated || _token == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      _usuario = await _obtenerDatosUsuario();
      
      await _storageService.saveAuthData(
        _userId!, 
        _token!, 
        _correo!,
        userType: _userType,
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
    _userType = null; // Limpiar tipo de usuario
    _usuario = null;
    
    await _storageService.clearAuthData();
    
    notifyListeners();
  }
}