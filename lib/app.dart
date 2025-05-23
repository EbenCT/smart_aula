import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Para soporte de localización
import 'config/routes.dart';
import 'config/themes.dart';
import 'providers/theme_provider.dart'; // Nueva importación
import 'screens/login/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/home/home_screen.dart';

class AulaInteligenteApp extends StatelessWidget {
  const AulaInteligenteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, ThemeProvider>(
      builder: (context, authService, themeProvider, _) {
        return MaterialApp(
          title: 'Aula Inteligente',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode, // Usar el tema del provider
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
          locale: const Locale('es', ''), // Establecer español como idioma predeterminado
          
          home: authService.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}