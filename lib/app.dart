import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/routes.dart';
import 'config/themes.dart';
import 'providers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/estudiantes/estudiante_home_screen.dart';
import 'screens/padre/padre_home_screen.dart';

class AulaInteligenteApp extends StatelessWidget {
  const AulaInteligenteApp({Key? key}) : super(key: key);

  // Función para determinar la pantalla inicial según el tipo de usuario
  Widget _getHomeScreenForUserType(String? userType) {
    switch (userType) {
      case 'admin':
      case 'docente':
        return const HomeScreen(); // Pantalla existente para docentes/admin
      case 'estudiante':
        return const EstudianteHomeScreen(); // Nueva pantalla para estudiantes
      case 'padre':
        return const PadreHomeScreen(); // Nueva pantalla para padres
      default:
        // Si no hay tipo de usuario definido, redirigir al login
        return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, ThemeProvider>(
      builder: (context, authService, themeProvider, _) {
        return MaterialApp(
          title: 'Aula Inteligente',
          theme: AppThemes.lightTheme,
          debugShowCheckedModeBanner: false,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          routes: AppRoutes.routes,
          
          // Configuración de localización
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', ''), // Español
            Locale('en', ''), // Inglés
          ],
          locale: const Locale('es', ''), // Español como idioma predeterminado
          
          // Navegación basada en autenticación y tipo de usuario
          home: authService.isAuthenticated
              ? _getHomeScreenForUserType(authService.userType)
              : const LoginScreen(),
        );
      },
    );
  }
}