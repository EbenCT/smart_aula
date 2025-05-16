import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/periodo_provider.dart';
import 'providers/curso_provider.dart';
import 'providers/estudiantes_provider.dart';
import 'providers/asistencia_provider.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PeriodoProvider()),
        ChangeNotifierProvider(create: (_) => CursoProvider()),
        ChangeNotifierProvider(create: (_) => EstudiantesProvider()),
        ChangeNotifierProvider(create: (_) => AsistenciaProvider()),
      ],
      child: const AulaInteligenteApp(),
    ),
  );
}