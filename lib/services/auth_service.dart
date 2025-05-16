import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get token => _token;

  // Constructor con simulación de autenticación para desarrollo
  AuthService() {
    // Autenticación simulada para desarrollo
    if (kDebugMode) {
      _isAuthenticated = true;
      _userId = 'user123';
      _token = 'token123';
    }
  }

  Future<void> login(String email, String password) async {
    // Simular autenticación
    await Future.delayed(const Duration(seconds: 1));
    
    // En producción, aquí iría la llamada API real
    if (email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      _userId = 'user123';
      _token = 'token123';
      notifyListeners();
    } else {
      throw Exception('Credenciales inválidas');
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _token = null;
    notifyListeners();
  }
}