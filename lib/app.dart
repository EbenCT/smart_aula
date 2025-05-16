import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/themes.dart';
import 'screens/login/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/home/home_screen.dart';

class AulaInteligenteApp extends StatelessWidget {
  const AulaInteligenteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aula Inteligente',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      routes: AppRoutes.routes,
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          return authService.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}