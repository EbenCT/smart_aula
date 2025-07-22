import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/seleccion/seleccion_curso_materia_screen.dart';
import '../../screens/asistencia/lista_asistencia_screen.dart';
import '../../screens/participacion/registro_participacion_screen.dart';
import '../../screens/estudiantes/lista_estudiantes_screen.dart';
import '../screens/login/login_screen.dart';
import 'theme_toggle_button.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header del drawer con información del usuario
            Flexible(
              flex: 0,
              child: _buildDrawerHeader(context),
            ),
            
            // Opciones de navegación - En scroll si es necesario
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    
                    // Navegación principal
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                      },
                    ),
                    Divider(color: Theme.of(context).dividerColor),
                    
                    ListTile(
                      leading: const Icon(Icons.filter_list),
                      title: const Text('Cambiar Curso/Materia'),
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(
                          SeleccionCursoMateriaScreen.routeName
                        );
                      },
                    ),
                    Divider(color: Theme.of(context).dividerColor),
                    
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
                    
                    const SizedBox(height: 16),
                    Divider(color: Theme.of(context).dividerColor),
                    
                    // Opciones de tema
                    _buildThemeSection(context),
                    Divider(color: Theme.of(context).dividerColor),
                    
                    // Opción para ver perfil
                    ListTile(
                      leading: Icon(
                        Icons.account_circle, 
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        'Mi Perfil',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                      },
                    ),
                    
                    // Opción de cerrar sesión
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
                            backgroundColor: Theme.of(context).dialogBackgroundColor,
                            title: Text(
                              'Cerrar Sesión',
                              style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                            ),
                            content: Text(
                              '¿Está seguro que desea cerrar sesión?',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                                child: Text(
                                  'CANCELAR',
                                  style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop(); // Cerrar diálogo
                                  Navigator.of(context).pop(); // Cerrar drawer
                                  // Ejecutar logout después de la navegación
                                  Provider.of<AuthService>(context, listen: false).logout();
                                  // Redirigir directamente al LoginScreen
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (route) => false,
                                  );                                                                  
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final usuario = authService.usuario;
        
        return UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          accountName: usuario != null 
              ? Text(
                  usuario.nombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : const Text(
                  'Usuario',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          accountEmail: usuario != null 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.correo,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (usuario.telefono.isNotEmpty)
                      Text(
                        usuario.telefono,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                )
              : Text(
                  authService.correo ?? 'Sin correo',
                  style: const TextStyle(fontSize: 14),
                ),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: usuario != null
                ? Text(
                    usuario.nombre.isNotEmpty && usuario.apellido.isNotEmpty
                        ? usuario.nombre.substring(0, 1) + usuario.apellido.substring(0, 1)
                        : usuario.correo.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
          ),
          otherAccountsPictures: [
            if (usuario?.isDoc == true)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: Icon(
            themeProvider.themeIcon,
            color: Theme.of(context).iconTheme.color,
          ),
          title: Text(themeProvider.themeText),
          trailing: const QuickThemeToggle(),
          onTap: () async {
            await themeProvider.toggleTheme();
          },
        );
      },
    );
  }
}