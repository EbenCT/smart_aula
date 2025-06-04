// lib/screens/dashboard/dashboard_screen.dart
// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/resumen_provider.dart';
import '../../screens/estudiantes/detalle_estudiante_screen.dart';
import '../../models/estudiante.dart';
import '../../models/resumen_materia.dart';
import '../../widgets/resumen_card.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  bool _dataLoaded = false;
  DateTime? _lastRefresh;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  // Cargar datos iniciales de forma optimizada
  Future<void> _cargarDatosIniciales() async {
    if (_dataLoaded && _isDataFresh()) return;

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context, listen: false);
    final resumenProvider = Provider.of<ResumenProvider>(context, listen: false);

    if (!cursoProvider.tieneSeleccionCompleta) return;

    final cursoSeleccionado = cursoProvider.cursoSeleccionado!;
    final materiaSeleccionada = cursoProvider.materiaSeleccionada!;

    try {
      // Cargar datos en paralelo para optimizar
      await Future.wait([
        resumenProvider.cargarResumenMateria(
          cursoSeleccionado.id,
          materiaSeleccionada.id,
        ),
        estudiantesProvider.cargarEstudiantesPorMateria(
          cursoSeleccionado.id,
          materiaSeleccionada.id,
        ),
      ]);

      _dataLoaded = true;
      _lastRefresh = DateTime.now();
    } catch (e) {
      // Error manejado por los providers individuales
      debugPrint('Error cargando datos del dashboard: $e');
    }
  }

  // Verificar si los datos están frescos (15 minutos)
  bool _isDataFresh() {
    if (_lastRefresh == null) return false;
    final now = DateTime.now();
    return now.difference(_lastRefresh!).inMinutes < 15;
  }

  // Refrescar datos de forma inteligente
  Future<void> _refreshData({bool force = false}) async {
    if (!force && _isDataFresh()) {
      _showRefreshMessage('Datos actualizados recientemente');
      return;
    }

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context, listen: false);
    final resumenProvider = Provider.of<ResumenProvider>(context, listen: false);

    if (!cursoProvider.tieneSeleccionCompleta) return;

    try {
      final cursoSeleccionado = cursoProvider.cursoSeleccionado!;
      final materiaSeleccionada = cursoProvider.materiaSeleccionada!;

      // Refrescar en paralelo
      await Future.wait([
        resumenProvider.recargarResumen(force: true),
        estudiantesProvider.recargarEstudiantes(force: true),
      ]);

      _lastRefresh = DateTime.now();
      _showRefreshMessage('Dashboard actualizado');
    } catch (e) {
      _showRefreshMessage('Error al actualizar', isError: true);
    }
  }

  void _showRefreshMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer3<CursoProvider, EstudiantesProvider, ResumenProvider>(
      builder: (context, cursoProvider, estudiantesProvider, resumenProvider, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;
        
        if (!cursoProvider.tieneSeleccionCompleta) {
          return _buildEmptyState();
        }

        // Cargar datos cuando hay selección completa (solo si no están cargados)
        if (!_dataLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _cargarDatosIniciales();
          });
        }

        // Estado de carga inicial
        if (resumenProvider.isLoading && !_dataLoaded) {
          return _buildLoadingState();
        }
        
        // Estado de error
        if (resumenProvider.errorMessage != null && !_dataLoaded) {
          return _buildErrorState(resumenProvider.errorMessage!);
        }

        final resumenMateria = resumenProvider.resumenMateria;
        final estudiantes = estudiantesProvider.estudiantes;
        
        if (resumenMateria == null && _dataLoaded) {
          return _buildNoDataState();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () => _refreshData(force: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con información del curso
                    _buildHeaderCard(context, cursoSeleccionado!, materiaSeleccionada!, isDarkMode),
                    
                    const SizedBox(height: 16),
                    
                    if (resumenMateria != null) ...[
                      // Tarjetas principales de estadísticas
                      _buildMainStatsCards(context, resumenMateria),
                      
                      const SizedBox(height: 16),
                      
                      // Tarjetas detalladas
                      _buildDetailedStatsCards(context, resumenMateria),
                      
                      // Sección de estudiantes (optimizada)
                      if (estudiantes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildEstudiantesSection(context, estudiantes, isDarkMode),
                      ],
                      
                      // Análisis de datos
                      const SizedBox(height: 24),
                      _buildAnalisisSection(context, resumenMateria, isDarkMode),
                    ],
                    
                    const SizedBox(height: 80), // Espacio para el FAB
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _buildRefreshFAB(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 72,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un curso y materia',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
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

  Widget _buildErrorState(String error) {
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
            error,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _refreshData(force: true),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 72,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin datos disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshFAB() {
    return FloatingActionButton(
      onPressed: () => _refreshData(),
      backgroundColor: Theme.of(context).primaryColor,
      tooltip: 'Actualizar dashboard',
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }

  // ... (resto de métodos de construcción de widgets permanecen iguales)
  
  Widget _buildHeaderCard(BuildContext context, curso, materia, bool isDarkMode) {
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
            Icon(Icons.school, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia.nombre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    curso.nombreCompleto,
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

  Widget _buildMainStatsCards(BuildContext context, ResumenMateriaCompleto resumen) {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: 'Estudiantes',
            valor: resumen.totalEstudiantes.toString(),
            icono: Icons.people,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Asistencia',
            valor: '${resumen.promedioGeneral.asistencia.toStringAsFixed(1)}%',
            icono: Icons.calendar_today,
            color: _getColorForAsistencia(resumen.promedioGeneral.asistencia),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStatsCards(BuildContext context, ResumenMateriaCompleto resumen) {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: resumen.tieneNotas ? 'Promedio Notas' : 'Sin Notas',
            valor: resumen.tieneNotas 
                ? resumen.promedioGeneral.notas.toStringAsFixed(1)
                : 'N/A',
            icono: Icons.school,
            color: resumen.tieneNotas 
                ? _getColorForNota(resumen.promedioGeneral.notas)
                : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Participación',
            valor: resumen.promedioGeneral.participacion.toStringAsFixed(2),
            icono: Icons.record_voice_over,
            color: _getColorForParticipacion(resumen.promedioGeneral.participacion),
          ),
        ),
      ],
    );
  }

  Widget _buildEstudiantesSection(BuildContext context, List<Estudiante> estudiantes, bool isDarkMode) {
    // Mostrar solo primeros 3 estudiantes para optimizar
    final estudiantesMuestra = estudiantes.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estudiantes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/estudiantes'),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: isDarkMode ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: estudiantesMuestra.map((estudiante) {
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
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      estudiante.nombre.substring(0, 1) + estudiante.apellido.substring(0, 1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    estudiante.nombreCompleto,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text('Código: ${estudiante.codigo}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => DetalleEstudianteScreen(
                          estudianteId: estudiante.id.toString(),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalisisSection(BuildContext context, ResumenMateriaCompleto resumen, bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Resumen General',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              '✓ ${resumen.tieneNotas ? "Calificaciones registradas" : "Sin calificaciones"}',
              style: TextStyle(
                color: resumen.tieneNotas ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              '✓ Asistencia: ${resumen.promedioGeneral.asistencia.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getColorForAsistencia(resumen.promedioGeneral.asistencia),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              '✓ Participación: ${resumen.promedioGeneral.participacion.toStringAsFixed(2)}',
              style: TextStyle(
                color: _getColorForParticipacion(resumen.promedioGeneral.participacion),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForNota(double nota) {
    if (nota >= 80) return Colors.green;
    if (nota >= 60) return Colors.amber;
    return Colors.red;
  }

  Color _getColorForAsistencia(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 75) return Colors.amber;
    return Colors.red;
  }

  Color _getColorForParticipacion(double promedio) {
    if (promedio >= 1.0) return Colors.green;
    if (promedio >= 0.5) return Colors.amber;
    return Colors.orange;
  }
}