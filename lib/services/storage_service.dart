import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _correoKey = 'correo';
  static const String _userTypeKey = 'user_type'; // Nueva clave para tipo de usuario
  static const String _usuarioKey = 'usuario_data';

  // Guardar datos de autenticación incluyendo tipo de usuario
  Future<void> saveAuthData(
    String userId, 
    String token, 
    String correo, {
    String? userType, // Nuevo parámetro
    Usuario? usuario,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_correoKey, correo);
    
    // Guardar tipo de usuario si se proporciona
    if (userType != null) {
      await prefs.setString(_userTypeKey, userType);
    }
    
    // Guardar datos del usuario si se proporcionan
    if (usuario != null) {
      await prefs.setString(_usuarioKey, json.encode(usuario.toJson()));
    }
  }

  // Obtener datos de autenticación incluyendo tipo de usuario
  Future<Map<String, dynamic>?> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final token = prefs.getString(_tokenKey);
    final userId = prefs.getString(_userIdKey);
    final correo = prefs.getString(_correoKey);
    final userType = prefs.getString(_userTypeKey); // Obtener tipo de usuario
    final usuarioData = prefs.getString(_usuarioKey);
    
    if (token != null && userId != null && correo != null) {
      final result = {
        'token': token,
        'userId': userId,
        'correo': correo,
        'userType': userType, // Incluir tipo de usuario
      };
      
      // Incluir datos del usuario si existen
      if (usuarioData != null) {
        try {
          result['usuario'] = json.decode(usuarioData);
        } catch (e) {
          // Si hay error al decodificar, simplemente no incluir los datos del usuario
        }
      }
      
      return result;
    }
    
    return null;
  }

  // Limpiar todos los datos de autenticación
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_correoKey);
    await prefs.remove(_userTypeKey); // Limpiar tipo de usuario
    await prefs.remove(_usuarioKey);
  }

  // Métodos individuales para obtener datos específicos
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getCorreo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_correoKey);
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  Future<Usuario?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioData = prefs.getString(_usuarioKey);
    
    if (usuarioData != null) {
      try {
        return Usuario.fromJson(json.decode(usuarioData));
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
}