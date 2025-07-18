// lib/screens/estudiantes/estudiante_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/resumen_card.dart';
import '../../models/dashboard_estudiante.dart';
import '../../screens/estudiantes/detalle_materia_estudiante_screen.dart';

class EstudianteHomeScreen extends StatefulWidget {
  static const routeName = '/estudiante-home';

  const EstudianteHomeScreen({Key? key}) : super(key: key);

  @override
  _EstudianteHomeScreenState createState() => _EstudianteHomeScreenState();
}

class _EstudianteHomeScreenState extends State<EstudianteHomeScreen> {
  DashboardEstudiante? _dashboard;
  bool _isLoading = false;
  String? _error;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getDashboardEstudiante();
      if (response['success'] == true) {
        setState(() {
          _dashboard = DashboardEstudiante.fromJson(response);
        });
      } else {
        setState(() {
          _error = response['mensaje'] ?? 'Error al cargar datos';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Portal Estudiante'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _cargarDashboard,
                tooltip: 'Actualizar',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, authService),
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboard == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando dashboard...'),
          ],
        ),
      );
    }

    if (_error != null && _dashboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargarDashboard,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_dashboard == null) {
      return Center(
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
              'No hay información disponible',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _cargarDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - reutilizando el estilo del dashboard del profesor
              _buildHeaderCard(),
              
              const SizedBox(height: 16),
              
              // Estadísticas principales - reutilizando ResumenCard
              _buildMainStatsCards(),
              
              const SizedBox(height: 16),
              
              // Estadísticas detalladas - reutilizando ResumenCard
              _buildDetailedStatsCards(),
              
              const SizedBox(height: 24),
              
              // Lista de materias - reutilizando el estilo de estudiantes
              _buildMateriasSection(isDarkMode),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Reutilizando el estilo del header del dashboard del profesor
  Widget _buildHeaderCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dashboard!.nombreEstudiante,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    _dashboard!.nombreCurso,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reutilizando ResumenCard del dashboard del profesor
  Widget _buildMainStatsCards() {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: 'Materias',
            valor: _dashboard!.totalMaterias.toString(),
            icono: Icons.subject,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Docentes',
            valor: _dashboard!.totalDocentes.toString(),
            icono: Icons.people,
            color: _getColorForDocentes(_dashboard!.totalDocentes),
          ),
        ),
      ],
    );
  }

  // Reutilizando ResumenCard del dashboard del profesor
  Widget _buildDetailedStatsCards() {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: 'Con Docente',
            valor: _dashboard!.materiasConDocente.toString(),
            icono: Icons.check_circle,
            color: _getColorForMaterias(_dashboard!.materiasConDocente, _dashboard!.totalMaterias),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Completitud',
            valor: '${_dashboard!.porcentajeCompleto.toStringAsFixed(1)}%',
            icono: Icons.pie_chart,
            color: _getColorForPorcentaje(_dashboard!.porcentajeCompleto),
          ),
        ),
      ],
    );
  }

  // Reutilizando el estilo de lista del dashboard del profesor
  Widget _buildMateriasSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Materias',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: isDarkMode ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: _dashboard!.materias.map<Widget>((materia) {
              final materiaData = materia['materia'];
              final docenteData = materia['docente'];
              final tieneDocente = docenteData != null;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    tieneDocente ? Icons.school : Icons.warning,
                    color: tieneDocente ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  title: Text(
                    materiaData['nombre'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    tieneDocente 
                        ? 'Prof. ${docenteData['nombre']} ${docenteData['apellido']}'
                        : 'Sin docente asignado',
                    style: TextStyle(
                      color: tieneDocente 
                          ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                          : Colors.orange,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: tieneDocente ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _navigateToMateriaDetail(context, materiaData['id']),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Reutilizando métodos de color del dashboard del profesor
  Color _getColorForDocentes(int totalDocentes) {
    if (totalDocentes >= 4) return Colors.green;
    if (totalDocentes >= 2) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForMaterias(int materiasConDocente, int totalMaterias) {
    if (materiasConDocente == totalMaterias) return Colors.green;
    if (materiasConDocente >= totalMaterias * 0.7) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForPorcentaje(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 70) return Colors.orange;
    return Colors.red;
  }

  void _navigateToMateriaDetail(BuildContext context, int materiaId) {
    if (_dashboard == null) return;

    // Encontrar la materia seleccionada
    final materiaData = _dashboard!.materias.firstWhere(
      (m) => m['materia']['id'] == materiaId,
    );

    final materia = materiaData['materia'];
    final docente = materiaData['docente'];

    // Navegar a la nueva pantalla específica para estudiantes
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleMateriasEstudianteScreen(
          estudianteId: _dashboard!.estudiante['id'].toString(),
          materiaId: materia['id'],
          cursoId: _dashboard!.curso['id'],
          materiaNombre: materia['nombre'],
          cursoNombre: _dashboard!.curso['nombre'],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              authService.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );
  }
}