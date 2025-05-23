import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }
  
  bool get isLightMode {
    return _themeMode == ThemeMode.light;
  }
  
  bool get isSystemMode {
    return _themeMode == ThemeMode.system;
  }
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  // Cargar el modo de tema guardado
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);
      
      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
        notifyListeners();
      }
    } catch (e) {
      // Si hay error, usar el tema del sistema por defecto
      _themeMode = ThemeMode.system;
    }
  }
  
  // Guardar el modo de tema
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      // Manejar error si es necesario
      print('Error guardando tema: $e');
    }
  }
  
  // Cambiar a modo claro
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    await _saveThemeMode();
    notifyListeners();
  }
  
  // Cambiar a modo oscuro
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    await _saveThemeMode();
    notifyListeners();
  }
  
  // Cambiar a modo del sistema
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    await _saveThemeMode();
    notifyListeners();
  }
  
  // Alternar entre claro y oscuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }
  
  // Obtener el ícono apropiado para el tema actual
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
  
  // Obtener el texto descriptivo del tema actual
  String get themeText {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Modo Claro';
      case ThemeMode.dark:
        return 'Modo Oscuro';
      case ThemeMode.system:
        return 'Tema del Sistema';
    }
  }
}