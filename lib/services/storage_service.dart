import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class StorageService {
  static const String authKey = 'auth_data';
  static const String configKey = 'app_config';
  
  // Guardar datos de autenticación (ahora incluye datos del usuario)
  Future<void> saveAuthData(
    String userId, 
    String token, 
    String correo, {
    Usuario? usuario,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authData = jsonEncode({
      'userId': userId,
      'token': token,
      'correo': correo,
      'timestamp': DateTime.now().toIso8601String(),
      'usuario': usuario?.toJson(), // Guardar datos del usuario si existen
    });
    
    await prefs.setString(authKey, authData);
  }
  
  // Cargar datos de autenticación
  Future<Map<String, dynamic>?> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authDataStr = prefs.getString(authKey);
    
    if (authDataStr == null) {
      return null;
    }
    
    try {
      final authData = jsonDecode(authDataStr) as Map<String, dynamic>;
      
      // Verificar si el token ha expirado (24 horas)
      final timestamp = DateTime.parse(authData['timestamp']);
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      if (difference.inHours > 24) {
        // Token expirado, eliminar datos
        await prefs.remove(authKey);
        return null;
      }
      
      return authData;
    } catch (e) {
      return null;
    }
  }
  
  // Eliminar datos de autenticación
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authKey);
  }
  
  // Guardar configuración de la aplicación
  Future<void> saveConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(configKey, jsonEncode(config));
  }
  
  // Cargar configuración de la aplicación
  Future<Map<String, dynamic>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configStr = prefs.getString(configKey);
    
    if (configStr == null) {
      return {};
    }
    
    try {
      return jsonDecode(configStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}