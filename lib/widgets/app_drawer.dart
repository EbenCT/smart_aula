import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/seleccion/seleccion_periodo_curso_screen.dart';
import '../../screens/asistencia/lista_asistencia_screen.dart';
import '../../screens/participacion/registro_participacion_screen.dart';
import '../../screens/estudiantes/lista_estudiantes_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Aula Inteligente'),
            automaticallyImplyLeading: false,
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Cambiar Periodo/Curso'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                SeleccionPeriodoCursoScreen.routeName
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Gestión de Asistencia'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                ListaAsistenciaScreen.routeName
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('Registro de Participación'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                RegistroParticipacionScreen.routeName
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Lista de Estudiantes'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                ListaEstudiantesScreen.routeName
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Está seguro que desea cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('CANCELAR'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Provider.of<AuthService>(context, listen: false).logout();
                      },
                      child: const Text('ACEPTAR'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}