import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/routes.dart';
import 'config/themes.dart';
import 'providers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart'; // 🆕 NUEVO
import 'services/api_service.dart'; // 🆕 NUEVO
import 'screens/home/home_screen.dart';
import 'screens/estudiantes/estudiante_home_screen.dart';
import 'screens/padre/padre_home_screen.dart';
import 'utils/debug_logger.dart'; // 🆕 NUEVO

class AulaInteligenteApp extends StatefulWidget { // 🆕 CAMBIO: StatefulWidget
  const AulaInteligenteApp({Key? key}) : super(key: key);

  @override
  State<AulaInteligenteApp> createState() => _AulaInteligenteAppState();
}

class _AulaInteligenteAppState extends State<AulaInteligenteApp> 
    with WidgetsBindingObserver { // 🆕 NUEVO: Observer para ciclo de vida

  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // La inicialización se hará cuando el widget se construya y tengamos contexto
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopNotifications();
    super.dispose();
  }

  // 🆕 NUEVO: Manejar ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App volvió al foreground
        _initializeNotificationsIfNeeded();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App fue pausada o cerrada
        _stopNotifications();
        break;
    }
  }

  // 🆕 NUEVO: Inicializar notificaciones si es necesario
  Future<void> _initializeNotificationsIfNeeded() async {
    if (!mounted) return;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (authService.isAuthenticated && !_notificationsInitialized) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        final apiService = Provider.of<ApiService>(context, listen: false);
        
        await notificationService.initialize(apiService);
        await notificationService.startService();
        
        _notificationsInitialized = true;
        DebugLogger.info('Notificaciones inicializadas automáticamente');
      }
    } catch (e) {
      DebugLogger.error('Error inicializando notificaciones: $e');
    }
  }

  // 🆕 NUEVO: Detener notificaciones
  void _stopNotifications() {
    if (!mounted) return;
    
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.stopService();
      _notificationsInitialized = false;
      DebugLogger.info('Notificaciones detenidas');
    } catch (e) {
      DebugLogger.error('Error deteniendo notificaciones: $e');
    }
  }

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
        
        // 🆕 NUEVO: Inicializar notificaciones cuando el usuario esté autenticado
        if (authService.isAuthenticated && !_notificationsInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeNotificationsIfNeeded();
          });
        }
        
        // 🆕 NUEVO: Detener notificaciones si el usuario no está autenticado
        if (!authService.isAuthenticated && _notificationsInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _stopNotifications();
          });
        }

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