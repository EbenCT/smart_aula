// lib/screens/asistencia/lista_asistencia_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/curso_provider.dart';
import '../../models/asistencia.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/summary_stats_widget.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/asistencia_item.dart';

class ListaAsistenciaScreen extends StatefulWidget {
  static const routeName = '/asistencia';

  const ListaAsistenciaScreen({Key? key}) : super(key: key);

  @override
  _ListaAsistenciaScreenState createState() => _ListaAsistenciaScreenState();
}

class _ListaAsistenciaScreenState extends State<ListaAsistenciaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;
  String _searchQuery = '';
  bool _localeInitialized = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarAsistencia();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  Future<void> _cargarAsistencia() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      
      if (cursoProvider.cursoSeleccionado != null) {
        asistenciaProvider.setCursoId(cursoProvider.cursoSeleccionado!.id);
        asistenciaProvider.setFechaSeleccionada(_fechaSeleccionada);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar asistencia: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _fechaSeleccionada = newDate;
    });
    Provider.of<AsistenciaProvider>(context, listen: false)
        .setFechaSeleccionada(newDate);
    _cargarAsistencia();
  }

  @override
  Widget build(BuildContext context) {
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const EmptyStateWidget(
        icon: Icons.class_outlined,
        title: 'Seleccione un curso para ver la asistencia',
      );
    }

    var estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);
    
    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      estudiantes = estudiantes.where((e) => 
        e.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.codigo.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    final asistencias = asistenciaProvider.asistenciasPorCursoYFecha(
      cursoSeleccionado.id, 
      _fechaSeleccionada
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Cabecera con fecha y filtro
          SearchHeaderWidget(
            hintText: 'Buscar estudiante...',
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            controller: _searchController,
            searchValue: _searchQuery,
            additionalWidget: DateSelectorWidget(
              selectedDate: _fechaSeleccionada,
              onDateChanged: _onDateChanged,
              localeInitialized: _localeInitialized,
            ),
          ),
          
          // Resumen de asistencia
          if (estudiantes.isNotEmpty)
            _buildResumenAsistencia(asistencias, estudiantes.length),
          
          // Lista de estudiantes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : estudiantes.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: 'No hay estudiantes registrados',
                        subtitle: 'O no se encontraron estudiantes con el filtro actual',
                      )
                    : _buildEstudiantesList(estudiantes, asistencias, cursoSeleccionado.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarAsistencias,
        icon: const Icon(Icons.save),
        label: const Text('Guardar'),
        tooltip: 'Guardar asistencias',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildResumenAsistencia(List<Asistencia> asistencias, int totalEstudiantes) {
    int presentes = asistencias.where((a) => a.estado == EstadoAsistencia.presente).length;
    int tardanzas = asistencias.where((a) => a.estado == EstadoAsistencia.tardanza).length;
    int ausentes = asistencias.where((a) => a.estado == EstadoAsistencia.ausente).length;
    int justificados = asistencias.where((a) => a.estado == EstadoAsistencia.justificado).length;

    final stats = [
      SummaryStat(title: 'Presentes', count: presentes, color: Colors.green),
      SummaryStat(title: 'Tardes', count: tardanzas, color: Colors.amber),
      SummaryStat(title: 'Ausentes', count: ausentes, color: Colors.red),
      SummaryStat(title: 'Justificados', count: justificados, color: Colors.blue),
    ];

    final porcentajeAsistencia = totalEstudiantes > 0 
        ? ((presentes + tardanzas + justificados) * 100 / totalEstudiantes)
        : 0.0;

    return SummaryStatsWidget(
      title: 'Resumen de Asistencia',
      stats: stats,
      additionalInfo: Column(
        children: [
          LinearProgressIndicator(
            value: totalEstudiantes > 0 ? (presentes + tardanzas + justificados) / totalEstudiantes : 0,
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
            color: Colors.green,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            'Asistencia general: ${porcentajeAsistencia.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudiantesList(
    List<dynamic> estudiantes,
    List<Asistencia> asistencias,
    String cursoId,
  ) {
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: estudiantes.length,
      itemBuilder: (ctx, index) {
        final estudiante = estudiantes[index];
        final asistencia = asistencias.firstWhere(
          (a) => a.estudianteId == estudiante.id,
          orElse: () => Asistencia(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            estudianteId: estudiante.id,
            cursoId: cursoId,
            fecha: _fechaSeleccionada,
            estado: EstadoAsistencia.ausente,
          ),
        );
        
        return AsistenciaItem(
          estudiante: estudiante,
          asistencia: asistencia,
          onAsistenciaChanged: (EstadoAsistencia nuevoEstado) {
            final nuevaAsistencia = Asistencia(
              id: asistencia.id,
              estudianteId: estudiante.id,
              cursoId: cursoId,
              fecha: _fechaSeleccionada,
              estado: nuevoEstado,
              observacion: asistencia.observacion,
            );
            
            asistenciaProvider.registrarAsistencia(nuevaAsistencia);
          },
        );
      },
    );
  }

  void _guardarAsistencias() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Asistencias guardadas correctamente'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}