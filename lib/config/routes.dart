import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/seleccion/seleccion_curso_materia_screen.dart';
import '../screens/asistencia/lista_asistencia_screen.dart';
import '../screens/participacion/registro_participacion_screen.dart';
import '../screens/estudiantes/lista_estudiantes_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/estudiantes/estudiante_home_screen.dart'; // Nueva importación
import '../screens/padre/padre_home_screen.dart'; // Nueva importación

class AppRoutes {
  static final routes = <String, WidgetBuilder>{
    // Rutas existentes
    HomeScreen.routeName: (ctx) => const HomeScreen(),
    SeleccionCursoMateriaScreen.routeName: (ctx) => const SeleccionCursoMateriaScreen(),
    ListaAsistenciaScreen.routeName: (ctx) => const ListaAsistenciaScreen(),
    RegistroParticipacionScreen.routeName: (ctx) => const RegistroParticipacionScreen(),
    ListaEstudiantesScreen.routeName: (ctx) => const ListaEstudiantesScreen(),
    DashboardScreen.routeName: (ctx) => const DashboardScreen(),
    ProfileScreen.routeName: (ctx) => const ProfileScreen(),
    
    // Nuevas rutas para diferentes tipos de usuario
    EstudianteHomeScreen.routeName: (ctx) => const EstudianteHomeScreen(),
    PadreHomeScreen.routeName: (ctx) => const PadreHomeScreen(),
  };
}