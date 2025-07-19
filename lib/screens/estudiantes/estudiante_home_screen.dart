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
  @override
  Widget build(BuildContext context) {
    //super.build(context);
    
    if (_isLoading && _dashboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
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

    return Scaffold(
      body: RefreshIndicator(
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
                
                const SizedBox(height: 24),
                
                // NUEVO: Botón para marcar asistencia
                _buildMarcarAsistenciaButton(),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Agregar estos nuevos métodos al final de la clase _EstudianteHomeScreenState:

  // Construir el botón para marcar asistencia
  Widget _buildMarcarAsistenciaButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _mostrarSesionesActivas,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg, size: 24),
            const SizedBox(width: 12),
            Text(
              'Marcar Asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar las sesiones activas
  Future<void> _mostrarSesionesActivas() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService(authService);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Cargando sesiones activas...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final sesionesActivas = await apiService.estudiantes.getSesionesActivas();
      
      // Cerrar indicador de carga
      Navigator.of(context).pop();
      
      if (sesionesActivas.isEmpty) {
        // No hay sesiones activas
        _mostrarMensajeNoSesiones();
      } else {
        // Mostrar sesiones activas
        _mostrarModalSesionesActivas(sesionesActivas);
      }
    } catch (e) {
      // Cerrar indicador de carga
      Navigator.of(context).pop();
      
      // Mostrar error
      _mostrarErrorSesiones(e.toString());
    }
  }

  // Mostrar mensaje cuando no hay sesiones activas
  void _mostrarMensajeNoSesiones() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Sin sesiones activas'),
          ],
        ),
        content: Text('No hay sesiones de asistencia activas en este momento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Mostrar error al cargar sesiones
  void _mostrarErrorSesiones(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text('Error al cargar las sesiones activas: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Mostrar modal con las sesiones activas
  void _mostrarModalSesionesActivas(List<Map<String, dynamic>> sesiones) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del modal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.how_to_reg, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sesiones de Asistencia Activas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Lista de sesiones
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: sesiones.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sesion = sesiones[index];
                    return _buildSesionCard(sesion);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construir card para cada sesión
  Widget _buildSesionCard(Map<String, dynamic> sesion) {
    final materia = sesion['materia'] ?? {};
    final docente = sesion['docente'] ?? {};
    final miAsistencia = sesion['mi_asistencia'];
    
    // Verificar si ya marcó asistencia
    final yaMarcoAsistencia = miAsistencia != null;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sesión
            Text(
              sesion['titulo'] ?? 'Sesión de Asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Información de la materia
            Row(
              children: [
                Icon(Icons.book, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Materia: ${materia['nombre'] ?? 'No especificada'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Información del docente
            Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Docente: ${docente['nombre'] ?? ''} ${docente['apellido'] ?? ''}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estado de asistencia y botón
            if (yaMarcoAsistencia) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Asistencia ya marcada',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _marcarAsistencia(sesion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_reg, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Marcar Asistencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Marcar asistencia (placeholder para la funcionalidad futura)
  void _marcarAsistencia(Map<String, dynamic> sesion) {
    // Cerrar el modal actual
    Navigator.of(context).pop();
    
    // Mostrar mensaje temporal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Función de marcar asistencia será implementada próximamente'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
    
    // TODO: Aquí implementarás la lógica para marcar asistencia
    // según las instrucciones que me darás después
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