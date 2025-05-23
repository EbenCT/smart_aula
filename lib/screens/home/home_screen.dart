import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../providers/curso_provider.dart';
import '../seleccion/seleccion_curso_materia_screen.dart';
import '../asistencia/lista_asistencia_screen.dart';
import '../participacion/registro_participacion_screen.dart';
import '../estudiantes/lista_estudiantes_screen.dart';
import '../dashboard/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarOpciones();
      
      // Verificar que haya un curso y materia seleccionados
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      
      if (!cursoProvider.tieneSeleccionCompleta) {
        // Si no hay selección completa, ir a la pantalla de selección
        Navigator.of(context).pushReplacementNamed(
          SeleccionCursoMateriaScreen.routeName
        );
      }
    });
  }

  void _inicializarOpciones() {
    _widgetOptions.clear();
    _widgetOptions.addAll([
      const DashboardScreen(),
      const ListaAsistenciaScreen(),
      const RegistroParticipacionScreen(),
      const ListaEstudiantesScreen(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CursoProvider>(
      builder: (context, cursoProvider, child) {
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aula Inteligente'),
                if (cursoSeleccionado != null && materiaSeleccionada != null)
                  Text(
                    '${materiaSeleccionada.nombre} - ${cursoSeleccionado.codigo}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            actions: [
              // Botón de cambio rápido de tema
              const QuickThemeToggle(),
              
              // Botón de cambio de curso/materia
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    SeleccionCursoMateriaScreen.routeName
                  );
                },
                tooltip: 'Cambiar Curso/Materia',
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: cursoProvider.tieneSeleccionCompleta
              ? (_widgetOptions.isNotEmpty 
                  ? _widgetOptions.elementAt(_selectedIndex)
                  : const Center(child: CircularProgressIndicator()))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 72,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selecciona un curso y una materia para continuar',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            SeleccionCursoMateriaScreen.routeName
                          );
                        },
                        child: const Text('Seleccionar Curso y Materia'),
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: cursoProvider.tieneSeleccionCompleta
              ? BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: Colors.grey,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: 'Asistencia',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.record_voice_over),
                      label: 'Participación',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.school),
                      label: 'Estudiantes',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}