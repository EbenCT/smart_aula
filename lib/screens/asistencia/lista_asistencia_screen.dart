// lib/screens/asistencia/lista_asistencia_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/curso_provider.dart';
import '../../models/asistencia.dart';
import '../../utils/debug_logger.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/summary_stats_widget.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/asistencia_item.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ListaAsistenciaScreen extends StatefulWidget {
  static const routeName = '/asistencia';

  const ListaAsistenciaScreen({Key? key}) : super(key: key);

  @override
  _ListaAsistenciaScreenState createState() => _ListaAsistenciaScreenState();
}

class _ListaAsistenciaScreenState extends State<ListaAsistenciaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
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

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    
    if (!cursoProvider.tieneSeleccionCompleta) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cursoId = cursoProvider.cursoSeleccionado!.id;
      final materiaId = cursoProvider.materiaSeleccionada!.id;
      
      // Configurar el provider con los datos actuales
      asistenciaProvider.setCursoId(materiaId.toString());
      asistenciaProvider.setMateriaId(materiaId);
      asistenciaProvider.setFechaSeleccionada(_fechaSeleccionada);
      
      // Cargar asistencias desde el backend para la fecha seleccionada
      await asistenciaProvider.cargarAsistenciasDesdeBackend(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: _fechaSeleccionada,
      );
      
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
    _cargarAsistencia();
  }

  String _mapearEstadoAsistencia(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'presente';
      case EstadoAsistencia.ausente:
        return 'falta';
      case EstadoAsistencia.tardanza:
        return 'tarde';
      case EstadoAsistencia.justificado:
        return 'justificacion';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CursoProvider, EstudiantesProvider, AsistenciaProvider>(
      builder: (context, cursoProvider, estudiantesProvider, asistenciaProvider, child) {
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;
        
        if (!cursoProvider.tieneSeleccionCompleta) {
          return const EmptyStateWidget(
            icon: Icons.class_outlined,
            title: 'Seleccione un curso y una materia para ver la asistencia',
          );
        }

        // Cargar estudiantes cuando hay selección completa
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cursoSeleccionado != null && materiaSeleccionada != null) {
            estudiantesProvider.cargarEstudiantesPorMateria(
              cursoSeleccionado.id, 
              materiaSeleccionada.id
            );
          }
        });

        // Verificar estado de carga de estudiantes
        if (estudiantesProvider.isLoading) {
          return Scaffold(
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando estudiantes...'),
                ],
              ),
            ),
          );
        }

        if (estudiantesProvider.errorMessage != null) {
          return Scaffold(
            body: Center(
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
                    estudiantesProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      estudiantesProvider.recargarEstudiantes();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        var estudiantes = _searchQuery.isEmpty 
            ? estudiantesProvider.estudiantes
            : estudiantesProvider.buscarEstudiantes(_searchQuery);
        
        final asistencias = asistenciaProvider.asistenciasPorCursoYFecha(
          materiaSeleccionada!.id.toString(), 
          _fechaSeleccionada
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Cabecera con fecha, información de materia y filtro
              SearchHeaderWidget(
                hintText: 'Buscar estudiante...',
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                controller: _searchController,
                searchValue: _searchQuery,
                additionalWidget: Column(
                  children: [
                    // Información de la materia
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  materiaSeleccionada.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  cursoSeleccionado!.nombreCompleto,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Indicador de datos cargados
                          if (asistencias.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_download,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cargado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Selector de fecha
                    DateSelectorWidget(
                      selectedDate: _fechaSeleccionada,
                      onDateChanged: _onDateChanged,
                      localeInitialized: _localeInitialized,
                    ),
                  ],
                ),
              ),
              
              // Resumen de asistencia
              if (estudiantes.isNotEmpty)
                _buildResumenAsistencia(asistencias, estudiantes.length),
              
              // Lista de estudiantes
              Expanded(
                child: _isLoading || asistenciaProvider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Cargando asistencias...'),
                          ],
                        ),
                      )
                    : estudiantes.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.people_outline,
                            title: 'No hay estudiantes registrados',
                            subtitle: 'O no se encontraron estudiantes con el filtro actual',
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await estudiantesProvider.recargarEstudiantes();
                              await _cargarAsistencia();
                            },
                            child: _buildEstudiantesList(estudiantes, asistencias, materiaSeleccionada.id.toString()),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _isSaving ? null : () => _guardarAsistencias(context),
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
            tooltip: 'Guardar asistencias',
            backgroundColor: _isSaving ? Colors.grey : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildResumenAsistencia(List<Asistencia> asistencias, int totalEstudiantes) {
    int presentes = asistencias.where((a) => a.estado == EstadoAsistencia.presente).length;
    int tardanzas = asistencias.where((a) => a.estado == EstadoAsistencia.tardanza).length;
    int ausentes = asistencias.where((a) => a.estado == EstadoAsistencia.ausente).length;
    int justificados = asistencias.where((a) => a.estado == EstadoAsistencia.justificado).length;

    // Calcular ausentes reales (estudiantes sin registro de asistencia)
    int ausentesReales = totalEstudiantes - asistencias.length + ausentes;

    final stats = [
      SummaryStat(title: 'Presentes', count: presentes, color: Colors.green),
      SummaryStat(title: 'Tardes', count: tardanzas, color: Colors.amber),
      SummaryStat(title: 'Ausentes', count: ausentesReales, color: Colors.red),
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
          if (asistencias.isNotEmpty)
            Text(
              'Datos cargados desde el servidor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEstudiantesList(
    List<dynamic> estudiantes,
    List<Asistencia> asistencias,
    String materiaId,
  ) {
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: estudiantes.length,
      itemBuilder: (ctx, index) {
        final estudiante = estudiantes[index];
        
        // Buscar asistencia existente o crear una por defecto
        final asistenciaExistente = asistenciaProvider.getAsistenciaEstudiante(
          estudiante.id.toString(), 
          _fechaSeleccionada
        );
        
        final asistencia = asistenciaExistente ?? Asistencia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          estudianteId: estudiante.id.toString(),
          cursoId: materiaId,
          fecha: _fechaSeleccionada,
          estado: EstadoAsistencia.ausente,
        );
        
        return AsistenciaItem(
          estudiante: estudiante,
          asistencia: asistencia,
          onAsistenciaChanged: (EstadoAsistencia nuevoEstado) {
            final nuevaAsistencia = Asistencia(
              id: asistencia.id,
              estudianteId: estudiante.id.toString(),
              cursoId: materiaId,
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

// lib/screens/asistencia/lista_asistencia_screen.dart - Método _guardarAsistencias con logs
Future<void> _guardarAsistencias(BuildContext context) async {
  DebugLogger.info('=== INICIANDO GUARDADO DE ASISTENCIAS ===', tag: 'ASISTENCIA_SCREEN');
  
  setState(() {
    _isSaving = true;
  });

  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    DebugLogger.info('Providers obtenidos correctamente', tag: 'ASISTENCIA_SCREEN');

    // Verificar que tenemos la información necesaria
    if (!cursoProvider.tieneSeleccionCompleta) {
      throw Exception('No hay curso y materia seleccionados');
    }

    final docenteId = authService.usuario?.id;
    if (docenteId == null) {
      throw Exception('No se pudo obtener el ID del docente');
    }

    final cursoId = cursoProvider.cursoSeleccionado!.id;
    final materiaId = cursoProvider.materiaSeleccionada!.id;
    final estudiantes = estudiantesProvider.estudiantes;

    DebugLogger.info('Datos de contexto:', tag: 'ASISTENCIA_SCREEN');
    DebugLogger.info('- Docente ID: $docenteId', tag: 'ASISTENCIA_SCREEN');
    DebugLogger.info('- Curso ID: $cursoId', tag: 'ASISTENCIA_SCREEN');
    DebugLogger.info('- Materia ID: $materiaId', tag: 'ASISTENCIA_SCREEN');
    DebugLogger.info('- Fecha: $_fechaSeleccionada', tag: 'ASISTENCIA_SCREEN');
    DebugLogger.info('- Número de estudiantes: ${estudiantes.length}', tag: 'ASISTENCIA_SCREEN');

    if (estudiantes.isEmpty) {
      throw Exception('No hay estudiantes para registrar asistencia');
    }

    // Preparar datos para el backend
    List<Map<String, dynamic>> asistenciasData = [];

    DebugLogger.info('Preparando datos de asistencia...', tag: 'ASISTENCIA_SCREEN');

    for (final estudiante in estudiantes) {
      // Buscar la asistencia del estudiante o usar ausente por defecto
      final asistencia = asistenciaProvider.getAsistenciaEstudiante(
        estudiante.id.toString(),
        _fechaSeleccionada,
      );

      final estadoFinal = asistencia?.estado ?? EstadoAsistencia.ausente;
      final estadoMapeado = _mapearEstadoAsistencia(estadoFinal);

      DebugLogger.info('Estudiante ${estudiante.id} (${estudiante.nombreCompleto}): $estadoFinal -> $estadoMapeado', tag: 'ASISTENCIA_SCREEN');

      asistenciasData.add({
        'id': estudiante.id,
        'estado': estadoMapeado,
      });
    }

    DebugLogger.info('Datos preparados para envío:', tag: 'ASISTENCIA_SCREEN');
    DebugLogger.info('Número de asistencias: ${asistenciasData.length}', tag: 'ASISTENCIA_SCREEN');
    DebugLogger.info('Primeras 3 asistencias: ${asistenciasData.take(3).toList()}', tag: 'ASISTENCIA_SCREEN');

    // Enviar al backend
    DebugLogger.info('Enviando asistencias al backend...', tag: 'ASISTENCIA_SCREEN');
    
    await apiService.enviarAsistencias(
      docenteId: docenteId,
      cursoId: cursoId,
      materiaId: materiaId,
      fecha: _fechaSeleccionada,
      asistencias: asistenciasData,
    );

    DebugLogger.info('Asistencias enviadas exitosamente', tag: 'ASISTENCIA_SCREEN');

    if (mounted) {
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

      // Recargar asistencias después de guardar para sincronizar con el servidor
      DebugLogger.info('Recargando asistencias después de guardar...', tag: 'ASISTENCIA_SCREEN');
      await _cargarAsistencia();
    }

  } catch (error) {
    DebugLogger.error('Error al guardar asistencias', tag: 'ASISTENCIA_SCREEN', error: error);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${error.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
    DebugLogger.info('=== GUARDADO DE ASISTENCIAS FINALIZADO ===', tag: 'ASISTENCIA_SCREEN');
  }
}
}