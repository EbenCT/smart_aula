// lib/screens/participacion/registro_participacion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/participacion_provider.dart';
import '../../models/participacion.dart';
import '../../models/estudiante.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/summary_stats_widget.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/student_list_item_widget.dart';
import '../../widgets/participation_type_selector_widget.dart';
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
  DateTime _fechaSeleccionada = DateTime.now();
  String _searchQuery = '';
  bool _localeInitialized = false;
  bool _isSaving = false;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Para almacenar participaciones locales nuevas (las que se crean en la sesión actual)
  final Map<String, List<Participacion>> _participacionesLocales = {};
  
  @override
  void initState() {
    super.initState();
    _initializeLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarParticipaciones();
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

  Future<void> _cargarParticipaciones() async {
    if (!mounted) return;

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final participacionProvider = Provider.of<ParticipacionProvider>(context, listen: false);
    
    if (!cursoProvider.tieneSeleccionCompleta) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cursoId = cursoProvider.cursoSeleccionado!.id;
      final materiaId = cursoProvider.materiaSeleccionada!.id;
      
      // Configurar el provider con los datos actuales
      participacionProvider.setCursoId(materiaId.toString());
      participacionProvider.setMateriaId(materiaId);
      participacionProvider.setFechaSeleccionada(_fechaSeleccionada);
      
      // Cargar participaciones desde el backend para la fecha seleccionada
      await participacionProvider.cargarParticipacionesDesdeBackend(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: _fechaSeleccionada,
      );
      
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar participaciones: ${error.toString()}'),
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
    _cargarParticipaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CursoProvider, EstudiantesProvider, ParticipacionProvider>(
      builder: (context, cursoProvider, estudiantesProvider, participacionProvider, child) {
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

        // Obtener participaciones del backend para la fecha seleccionada
        final participacionesBackend = participacionProvider.participacionesPorCursoYFecha(
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
                          if (participacionesBackend.isNotEmpty)
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
                      label: 'Fecha de participaciones',
                      localeInitialized: _localeInitialized,
                    ),
                  ],
                ),
              ),
              
              // Resumen de participaciones
              if (estudiantes.isNotEmpty)
                _buildParticipacionesSummary(estudiantes.length, participacionesBackend, materiaSeleccionada.id.toString()),
              
              // Lista de estudiantes
              Expanded(
                child: _isLoading || participacionProvider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Cargando participaciones...'),
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
                              await _cargarParticipaciones();
                            },
                            child: _buildEstudiantesList(estudiantes, materiaSeleccionada.id.toString(), participacionesBackend),
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

  Widget _buildParticipacionesSummary(int totalEstudiantes, List<Participacion> participacionesBackend, String materiaId) {
    // Combinar participaciones del backend con participaciones locales
    final Map<String, List<Participacion>> todasParticipaciones = {};
    
    // Agregar participaciones del backend
    for (var participacion in participacionesBackend) {
      if (!todasParticipaciones.containsKey(participacion.estudianteId)) {
        todasParticipaciones[participacion.estudianteId] = [];
      }
      todasParticipaciones[participacion.estudianteId]!.add(participacion);
    }
    
    // Agregar participaciones locales
    for (var entry in _participacionesLocales.entries) {
      final estudianteId = entry.key;
      final participacionesLocalesEstudiante = entry.value.where((p) => 
        p.fecha.year == _fechaSeleccionada.year && 
        p.fecha.month == _fechaSeleccionada.month && 
        p.fecha.day == _fechaSeleccionada.day
      ).toList();
      
      if (participacionesLocalesEstudiante.isNotEmpty) {
        if (!todasParticipaciones.containsKey(estudianteId)) {
          todasParticipaciones[estudianteId] = [];
        }
        todasParticipaciones[estudianteId]!.addAll(participacionesLocalesEstudiante);
      }
    }

    // Calcular estadísticas
    int totalParticipaciones = 0;
    int puntajeTotal = 0;
    int estudiantesConParticipacion = 0;

    for (var participacionesEstudiante in todasParticipaciones.values) {
      if (participacionesEstudiante.isNotEmpty) {
        final participacionesConValor = participacionesEstudiante.where((p) => p.valoracion > 0).toList();
        if (participacionesConValor.isNotEmpty) {
          estudiantesConParticipacion++;
          totalParticipaciones += participacionesConValor.length;
          for (var participacion in participacionesConValor) {
            puntajeTotal += participacion.valoracion;
          }
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
          if (participacionesBackend.isNotEmpty)
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

  Widget _buildEstudiantesList(List<Estudiante> estudiantes, String materiaId, List<Participacion> participacionesBackend) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: estudiantes.length,
      itemBuilder: (ctx, index) {
        final estudiante = estudiantes[index];
        
        // Obtener participaciones del backend para este estudiante
        final participacionesBackendEstudiante = participacionesBackend.where((p) => 
          p.estudianteId == estudiante.id.toString()
        ).toList();
        
        // Obtener participaciones locales del estudiante
        final participacionesLocalesEstudiante = _participacionesLocales[estudiante.id.toString()] ?? [];
        
        // Participaciones de la fecha seleccionada (combinando backend y locales)
        final participacionesFecha = [
          ...participacionesBackendEstudiante,
          ...participacionesLocalesEstudiante.where((p) => 
            p.fecha.year == _fechaSeleccionada.year && 
            p.fecha.month == _fechaSeleccionada.month && 
            p.fecha.day == _fechaSeleccionada.day
          ),
        ];
        
        return StudentListItemWidget(
          estudiante: estudiante,
          trailingWidget: _buildParticipacionesCounter(participacionesFecha.length, participacionesBackendEstudiante.isNotEmpty),
          bottomWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón para agregar participación
              ParticipationTypeSelectorWidget(
                estudianteId: estudiante.id.toString(),
                cursoId: materiaId,
                onParticipationRegistered: _registrarParticipacion,
              ),
              
              // Lista de participaciones de la fecha seleccionada
              if (participacionesFecha.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Participaciones de ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...participacionesFecha.map((p) => _buildParticipacionItem(estudiante.id.toString(), p, participacionesBackendEstudiante.contains(p))).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipacionesCounter(int count, bool tieneBackend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tieneBackend 
            ? Colors.green.withOpacity(0.1)
            : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: tieneBackend 
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tieneBackend) ...[
            Icon(
              Icons.cloud_done,
              size: 14,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            'Fecha: $count',
            style: TextStyle(
              color: tieneBackend 
                  ? Colors.green.shade700
                  : Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipacionItem(String estudianteId, Participacion participacion, bool esDelBackend) {
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        participacion.descripcion ?? 'Participación',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (esDelBackend)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Guardado',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
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
          // Solo permitir eliminar participaciones locales (no del backend)
          if (!esDelBackend)
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

    // Actualizar la fecha de la participación a la fecha seleccionada
    final participacionConFecha = Participacion(
      id: participacion.id,
      estudianteId: participacion.estudianteId,
      cursoId: participacion.cursoId,
      fecha: _fechaSeleccionada,
      tipo: participacion.tipo,
      descripcion: participacion.descripcion,
      valoracion: participacion.valoracion,
    );

    setState(() {
      if (!_participacionesLocales.containsKey(estudianteId)) {
        _participacionesLocales[estudianteId] = [];
      }
      _participacionesLocales[estudianteId]!.add(participacionConFecha);
    });
  }

  void _eliminarParticipacion(String estudianteId, Participacion participacion) {
    setState(() {
      _participacionesLocales[estudianteId]?.remove(participacion);
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
      final participacionProvider = Provider.of<ParticipacionProvider>(context, listen: false);
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

      // Obtener participaciones del backend para la fecha seleccionada
      final participacionesBackend = participacionProvider.participacionesPorCursoYFecha(
        materiaId.toString(), 
        _fechaSeleccionada
      );

      // Preparar datos para el backend
      List<Map<String, dynamic>> participacionesData = [];

      for (final estudiante in estudiantes) {
        // Buscar participación existente en el backend
        final participacionBackend = participacionesBackend.firstWhere(
          (p) => p.estudianteId == estudiante.id.toString(),
          orElse: () => Participacion(
            id: '',
            estudianteId: estudiante.id.toString(),
            cursoId: materiaId.toString(),
            fecha: _fechaSeleccionada,
            valoracion: 0,
            descripcion: 'No participó',
          ),
        );

        // Obtener participaciones locales del estudiante para la fecha seleccionada
        final participacionesLocalesEstudiante = _participacionesLocales[estudiante.id.toString()] ?? [];
        final participacionesFecha = participacionesLocalesEstudiante.where((p) => 
          p.fecha.year == _fechaSeleccionada.year && 
          p.fecha.month == _fechaSeleccionada.month && 
          p.fecha.day == _fechaSeleccionada.day
        ).toList();

        if (participacionesFecha.isNotEmpty) {
          // Si hay participaciones locales nuevas, calcular promedio y enviar
          final promedioPuntaje = participacionesFecha.isNotEmpty 
              ? (participacionesFecha.map((p) => p.valoracion).reduce((a, b) => a + b) / participacionesFecha.length).round()
              : 0;

          // Crear descripción combinada
          final descripciones = participacionesFecha
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
        } else if (participacionBackend.valoracion == 0) {
          // Si no hay participaciones locales y tampoco en el backend, enviar 0
          participacionesData.add({
            'id': estudiante.id,
            'valor': 0,
            'descripcion': 'No participó',
          });
        }
        // Si no hay participaciones locales pero sí en el backend, no enviamos nada (mantener lo que está)
      }

      // Solo enviar si hay datos que actualizar
      if (participacionesData.isNotEmpty) {
        // Enviar al backend - usando periodo_id = 1 como valor por defecto
        await apiService.enviarParticipaciones(
          docenteId: docenteId,
          cursoId: cursoId,
          materiaId: materiaId,
          periodoId: 1, // Valor por defecto, puedes ajustarlo según tu lógica
          fecha: _fechaSeleccionada,
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

          // Limpiar participaciones locales después de guardar exitosamente
          setState(() {
            _participacionesLocales.clear();
          });

          // Recargar participaciones desde el backend para sincronizar
          await _cargarParticipaciones();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No hay cambios que guardar'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
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
}