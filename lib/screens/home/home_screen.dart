import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/periodo_provider.dart';
import '../../providers/curso_provider.dart';
import '../seleccion/seleccion_periodo_curso_screen.dart';
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
      
      // Verificar que haya un periodo y curso seleccionado
      final periodoProvider = Provider.of<PeriodoProvider>(context, listen: false);
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      
      if (periodoProvider.periodoSeleccionado == null || 
          cursoProvider.cursoSeleccionado == null) {
        // Si no hay selección, ir a la pantalla de selección
        Navigator.of(context).pushReplacementNamed(
          SeleccionPeriodoCursoScreen.routeName
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
    final periodoProvider = Provider.of<PeriodoProvider>(context);
    final cursoProvider = Provider.of<CursoProvider>(context);
    
    final periodoSeleccionado = periodoProvider.periodoSeleccionado;
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aula Inteligente'),
            if (periodoSeleccionado != null && cursoSeleccionado != null)
              Text(
                '${cursoSeleccionado.codigo} - ${periodoSeleccionado.nombre}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.of(context).pushNamed(
                SeleccionPeriodoCursoScreen.routeName
              );
            },
            tooltip: 'Cambiar Periodo/Curso',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _widgetOptions.isNotEmpty 
          ? _widgetOptions.elementAt(_selectedIndex)
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }
}