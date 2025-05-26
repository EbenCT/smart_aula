import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/curso_provider.dart';
import 'providers/estudiantes_provider.dart';
import 'providers/asistencia_provider.dart';
import 'providers/participacion_provider.dart'; // Nueva importación
import 'providers/resumen_provider.dart';
import 'providers/theme_provider.dart';
import 'services/services.dart';

void main() async {
  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar datos de localización para español e inglés
  await initializeDateFormatting('es', null); 
  await initializeDateFormatting('en', null);
  
  runApp(
    MultiProvider(
      providers: [
        // Provider para el manejo de temas
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Primero registramos el AuthService ya que otros dependen de él
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // Luego registramos el ApiService que depende del AuthService
        ProxyProvider<AuthService, ApiService>(
          update: (context, authService, _) => ApiService(authService),
        ),
        
        // Ahora registramos los providers que pueden depender del ApiService
        ChangeNotifierProxyProvider<ApiService, CursoProvider>(
          create: (context) => CursoProvider(Provider.of<ApiService>(context, listen: false)),
          update: (context, apiService, previous) => previous ?? CursoProvider(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, EstudiantesProvider>(
          create: (context) => EstudiantesProvider(Provider.of<ApiService>(context, listen: false)),
          update: (context, apiService, previous) => previous ?? EstudiantesProvider(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, ResumenProvider>(
          create: (context) => ResumenProvider(Provider.of<ApiService>(context, listen: false)),
          update: (context, apiService, previous) => previous ?? ResumenProvider(apiService),
        ),
        
        // AsistenciaProvider depende del ApiService
        ChangeNotifierProxyProvider<ApiService, AsistenciaProvider>(
          create: (context) => AsistenciaProvider(Provider.of<ApiService>(context, listen: false)),
          update: (context, apiService, previous) => previous ?? AsistenciaProvider(apiService),
        ),
        
        // ParticipacionProvider también depende del ApiService
        ChangeNotifierProxyProvider<ApiService, ParticipacionProvider>(
          create: (context) => ParticipacionProvider(Provider.of<ApiService>(context, listen: false)),
          update: (context, apiService, previous) => previous ?? ParticipacionProvider(apiService),
        ),
      ],
      child: const AulaInteligenteApp(),
    ),
  );
}