// lib/screens/participacion/registro_participacion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../models/participacion.dart'; // Usando el archivo modificado
import '../../models/estudiante.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/summary_stats_widget.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/student_list_item_widget.dart';
import '../../widgets/participation_type_selector_widget.dart'; // Usando el archivo modificado
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class RegistroParticipacionScreen extends StatefulWidget {
  static const routeName = '/participacion';

  const RegistroParticipacionScreen({Key? key}) : super(key: key);

  @override
  _RegistroParticipacionScreenState createState() =>
      _RegistroParticipacionScreenState();
}

class _RegistroParticipacionScreenState
    extends State<RegistroParticipacionScreen> {
  final DateTime _fecha = DateTime.now();
  String _searchQuery = '';
  bool _localeInitialized = false;
  bool _isSaving = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Para almacenar participaciones locales
  final Map<String, List<Participacion>> _participaciones = {};
  
  @override
  void initState() {
    super.initState();
    _initializeLocale();
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<CursoProvider, EstudiantesProvider>(
      builder: (context, cursoProvider, estudiantesProvider, child) {
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;
        
        if (!cursoProvider.tieneSeleccionCompleta) {
          return const EmptyStateWidget(
            icon: Icons.class_outlined,
            title: 'Seleccione un curso y una materia para registrar participaciones',
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

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Cabecera con fecha actual, información de materia y filtro
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
                            Icons.record_voice_over,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  materiaSeleccionada!.nombre,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Fecha actual
                    DateSelectorWidget(
                      selectedDate: _fecha,
                      onDateChanged: (date) {}, // Fecha fija para hoy
                      label: 'Fecha actual',
                      localeInitialized: _localeInitialized,
                    ),
                  ],
                ),
              ),
              
              // Resumen de participaciones
              if (estudiantes.isNotEmpty)
                _buildParticipacionesSummary(estudiantes.length),
              
              // Lista de estudiantes
              Expanded(
                child: estudiantes.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: 'No hay estudiantes registrados',
                        subtitle: 'O no se encontraron estudiantes con el filtro actual',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await estudiantesProvider.recargarEstudiantes();
                        },
                        child: _buildEstudiantesList(estudiantes, materiaSeleccionada.id.toString()),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _isSaving ? null : () => _guardarParticipaciones(context),
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
            tooltip: 'Guardar participaciones',
            backgroundColor: _isSaving ? Colors.grey : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildParticipacionesSummary(int totalEstudiantes) {
    // Calcular estadísticas de participación
    int totalParticipaciones = 0;
    int puntajeTotal = 0;
    int estudiantesConParticipacion = 0;

    for (var participacionesEstudiante in _participaciones.values) {
      if (participacionesEstudiante.isNotEmpty) {
        estudiantesConParticipacion++;
        totalParticipaciones += participacionesEstudiante.length;
        for (var participacion in participacionesEstudiante) {
          puntajeTotal += participacion.valoracion;
        }
      }
    }

    final promedioParticipaciones = totalEstudiantes > 0 
        ? (totalParticipaciones / totalEstudiantes) 
        : 0.0;
    
    final promedioPuntaje = totalParticipaciones > 0 
        ? (puntajeTotal / totalParticipaciones) 
        : 0.0;

    final stats = [
      SummaryStat(title: 'Total', count: totalParticipaciones, color: Theme.of(context).primaryColor),
      SummaryStat(title: 'Estudiantes', count: estudiantesConParticipacion, color: Colors.blue),
      SummaryStat(title: 'Sin participar', count: totalEstudiantes - estudiantesConParticipacion, color: Colors.orange),
    ];

    return SummaryStatsWidget(
      title: 'Resumen de Participaciones',
      stats: stats,
      additionalInfo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Promedio: ${promedioParticipaciones.toStringAsFixed(1)} participaciones por estudiante',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Puntaje promedio: ${promedioPuntaje.toStringAsFixed(0)}/100',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _getColorForPuntaje(promedioPuntaje.toInt()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstudiantesList(List<Estudiante> estudiantes, String materiaId) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: estudiantes.length,
      itemBuilder: (ctx, index) {
        final estudiante = estudiantes[index];
        
        // Obtener participaciones del estudiante
        final participacionesEstudiante = _participaciones[estudiante.id.toString()] ?? [];
        
        // Participaciones de hoy
        final participacionesHoy = participacionesEstudiante.where((p) => 
          p.fecha.year == _fecha.year && 
          p.fecha.month == _fecha.month && 
          p.fecha.day == _fecha.day
        ).toList();
        
        return StudentListItemWidget(
          estudiante: estudiante,
          trailingWidget: _buildParticipacionesCounter(participacionesHoy.length),
          bottomWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón para agregar participación
              ParticipationTypeSelectorWidget(
                estudianteId: estudiante.id.toString(),
                cursoId: materiaId,
                onParticipationRegistered: _registrarParticipacion,
              ),
              
              // Lista de participaciones de hoy
              if (participacionesHoy.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Participaciones de hoy:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...participacionesHoy.map((p) => _buildParticipacionItem(estudiante.id.toString(), p)).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipacionesCounter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Hoy: $count',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildParticipacionItem(String estudianteId, Participacion participacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: participacion.getColorIndicador().withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Indicador de puntaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: participacion.getColorIndicador(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${participacion.valoracion}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participacion.descripcion ?? 'Participación',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  participacion.textoValoracion,
                  style: TextStyle(
                    color: participacion.getColorIndicador(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () {
              _eliminarParticipacion(estudianteId, participacion);
            },
          ),
        ],
      ),
    );
  }

  void _registrarParticipacion(
    String estudianteId,
    String cursoId,
    TipoParticipacion tipo,
    String descripcion,
    int valoracion,
  ) {
    final participacion = Participacion.nueva(
      estudianteId: estudianteId,
      cursoId: cursoId,
      descripcion: descripcion,
      valoracion: valoracion,
    );

    setState(() {
      if (!_participaciones.containsKey(estudianteId)) {
        _participaciones[estudianteId] = [];
      }
      _participaciones[estudianteId]!.add(participacion);
    });
  }

  void _eliminarParticipacion(String estudianteId, Participacion participacion) {
    setState(() {
      _participaciones[estudianteId]!.remove(participacion);
    });
  }

  Future<void> _guardarParticipaciones(BuildContext context) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      final estudiantesProvider = Provider.of<EstudiantesProvider>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

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

      if (estudiantes.isEmpty) {
        throw Exception('No hay estudiantes para registrar participaciones');
      }

      // Preparar datos para el backend
      List<Map<String, dynamic>> participacionesData = [];

      for (final estudiante in estudiantes) {
        // Obtener participaciones del estudiante para hoy
        final participacionesEstudiante = _participaciones[estudiante.id.toString()] ?? [];
        final participacionesHoy = participacionesEstudiante.where((p) => 
          p.fecha.year == _fecha.year && 
          p.fecha.month == _fecha.month && 
          p.fecha.day == _fecha.day
        ).toList();

        if (participacionesHoy.isNotEmpty) {
          // Calcular promedio de participaciones del día
          final promedioPuntaje = participacionesHoy.isNotEmpty 
              ? (participacionesHoy.map((p) => p.valoracion).reduce((a, b) => a + b) / participacionesHoy.length).round()
              : 0;

          // Crear descripción combinada
          final descripciones = participacionesHoy
              .map((p) => p.descripcion ?? 'Participación')
              .toSet() // Eliminar duplicados
              .toList();
          
          final descripcionCombinada = descripciones.length == 1 && descripciones.first == 'Participación'
              ? 'Participación'
              : descripciones.join('; ');

          participacionesData.add({
            'id': estudiante.id,
            'valor': promedioPuntaje,
            'descripcion': descripcionCombinada,
          });
        } else {
          // Si no hay participaciones, enviar valor 0
          participacionesData.add({
            'id': estudiante.id,
            'valor': 0,
            'descripcion': 'No participó',
          });
        }
      }

      // Enviar al backend - usando periodo_id = 1 como valor por defecto
      await apiService.enviarParticipaciones(
        docenteId: docenteId,
        cursoId: cursoId,
        materiaId: materiaId,
        periodoId: 1, // Valor por defecto, puedes ajustarlo según tu lógica
        fecha: _fecha,
        participaciones: participacionesData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Participaciones guardadas correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Limpiar participaciones después de guardar exitosamente
        setState(() {
          _participaciones.clear();
        });
      }

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar participaciones: ${error.toString()}'),
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
    }
  }

  Color _getColorForPuntaje(int puntaje) {
    if (puntaje >= 85) {
      return Colors.green;
    } else if (puntaje >= 70) {
      return Colors.lightGreen;
    } else if (puntaje >= 50) {
      return Colors.amber;
    } else if (puntaje >= 25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getTextForPuntaje(int puntaje) {
    if (puntaje >= 85) {
      return 'Excelente';
    } else if (puntaje >= 70) {
      return 'Muy Bueno';
    } else if (puntaje >= 50) {
      return 'Bueno';
    } else if (puntaje >= 25) {
      return 'Regular';
    } else {
      return 'Básico';
    }
  }
}