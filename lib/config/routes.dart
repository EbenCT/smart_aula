import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/seleccion/seleccion_periodo_curso_screen.dart';
import '../screens/asistencia/lista_asistencia_screen.dart';
import '../screens/participacion/registro_participacion_screen.dart';
import '../screens/estudiantes/lista_estudiantes_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart'; // Nueva importación

class AppRoutes {
  static final routes = <String, WidgetBuilder>{
    HomeScreen.routeName: (ctx) => const HomeScreen(),
    SeleccionPeriodoCursoScreen.routeName: (ctx) => const SeleccionPeriodoCursoScreen(),
    ListaAsistenciaScreen.routeName: (ctx) => const ListaAsistenciaScreen(),
    RegistroParticipacionScreen.routeName: (ctx) => const RegistroParticipacionScreen(),
    ListaEstudiantesScreen.routeName: (ctx) => const ListaEstudiantesScreen(),
    DashboardScreen.routeName: (ctx) => const DashboardScreen(),
    ProfileScreen.routeName: (ctx) => const ProfileScreen(), // Nueva ruta
  };
}