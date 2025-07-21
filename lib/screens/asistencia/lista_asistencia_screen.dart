// lib/screens/asistencia/lista_asistencia_screen.dart
import 'dart:async';

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
import '../../widgets/date_selector_widget.dart';
import '../../widgets/asistencia_item.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/sesion_asistencia_service.dart';
import '../../widgets/sesion_status_widget.dart';

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
  bool _isCreatingSession = false;
  late SesionAsistenciaService _sesionService;
  final TextEditingController _searchController = TextEditingController();
  bool _haySesionActiva = false;
  String? _nombreSesionActiva;
  int? _estudiantesPresentes = 0;
  int? _sesionActivaId;
  Timer? _timerActualizacion;
   bool _isCerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  // Inicializar el servicio de sesiones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _sesionService = SesionAsistenciaService(authService);
      _cargarAsistencia();
      _verificarSesionActiva();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timerActualizacion?.cancel();
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

  Future<void> _verificarSesionActiva() async {
    try {
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      if (!cursoProvider.tieneSeleccionCompleta) return;

      final sesiones = await _sesionService.obtenerMisSesiones(
        cursoId: cursoProvider.cursoSeleccionado!.id,
        materiaId: cursoProvider.materiaSeleccionada!.id,
        estado: 'activa',
      );

      if (sesiones.isNotEmpty && mounted) {
        final sesionActiva = sesiones.first;
        setState(() {
          _haySesionActiva = true;
          _nombreSesionActiva = sesionActiva['titulo'];
          _sesionActivaId = sesionActiva['id'];
        });
        
        // Obtener estadísticas de la sesión activa
        _obtenerEstadisticasSesion(sesionActiva['id']);
        // Iniciar polling para actualizar estudiantes presentes
        _iniciarActualizacionEstudiantes(sesionActiva['id']);
      }
    } catch (e) {
      DebugLogger.error('Error verificando sesión activa: $e');
    }
  }

  //Actualizar cantidad de estudiantes presentes
  void _iniciarActualizacionEstudiantes(int sesionId) {
    _timerActualizacion?.cancel(); // Cancelar timer anterior si existe
    _timerActualizacion = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_haySesionActiva) {
        timer.cancel();
        return;
      }
      _obtenerEstadisticasSesion(sesionId);
    });
  }

  // Obtener estadísticas de la sesión
  Future<void> _obtenerEstadisticasSesion(int sesionId) async {
    try {
      final estadisticas = await _sesionService.obtenerEstadisticasSesion(sesionId);
      
      if (mounted) {
        setState(() {
          _estudiantesPresentes = estadisticas['estadisticas']['presentes'] ?? 0;
        });
      }
    } catch (e) {
      DebugLogger.error('Error obteniendo estadísticas: $e');
    }
  }

Future<void> _cerrarSesion() async {
    if (_sesionActivaId == null) return;

    // Mostrar diálogo de confirmación
    final bool? confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Cerrar Sesión'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Está seguro que desea cerrar la sesión de asistencia activa?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información importante:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Los estudiantes ya no podrán marcar asistencia\n'
                      '• La sesión se sincronizará con el sistema de evaluaciones\n'
                      '• Esta acción no se puede deshacer',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó, proceder a cerrar la sesión
    if (confirmar == true && mounted) {
      await _ejecutarCierreSesion();
    }
  }

  // 4. Método para ejecutar el cierre de sesión
  Future<void> _ejecutarCierreSesion() async {
    setState(() {
      _isCerrandoSesion = true;
    });

    try {
      // Llamar al servicio para cerrar la sesión
      final resultado = await _sesionService.cerrarSesion(_sesionActivaId!);
      
      if (resultado != null && mounted) {
        // Actualizar el estado local
        setState(() {
          _haySesionActiva = false;
          _nombreSesionActiva = null;
          _estudiantesPresentes = 0;
          _sesionActivaId = null;
        });

        // Cancelar el timer de actualización
        _timerActualizacion?.cancel();

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultado['message'] ?? 'Sesión cerrada exitosamente',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Recargar la lista de asistencia
        await _cargarAsistencia();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al cerrar la sesión: ${error.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _cerrarSesion(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCerrandoSesion = false;
        });
      }
    }
  }
// Agregar este método para crear sesión automática
Future<void> _crearSesionAutomatica() async {
  if (!mounted) return;
  
  final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
  
  if (!cursoProvider.tieneSeleccionCompleta) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleccione un curso y materia primero'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() {
    _isCreatingSession = true;
  });

  try {
    // Obtener ubicación actual
    final location = await LocationService.instance.getCurrentLocation();
    
    if (location == null) {
      throw Exception('No se pudo obtener la ubicación. Verifique los permisos.');
    }

    // Crear sesión automática
    final resultado = await _sesionService.crearSesionAutomatica(
      cursoId: cursoProvider.cursoSeleccionado!.id,
      materiaId: cursoProvider.materiaSeleccionada!.id,
      latitud: location['latitude']!,
      longitud: location['longitude']!,
    );

    if (resultado != null && mounted) {
        
        setState(() {
          _haySesionActiva = true;
          _nombreSesionActiva = resultado['data']?['titulo'] ?? 'Sesión de Asistencia';
          _estudiantesPresentes = 0; // Inicialmente 0
          _sesionActivaId = resultado['data']?['id'];
        });

        
        if (_sesionActivaId != null) {
          _iniciarActualizacionEstudiantes(_sesionActivaId!);
        }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ Sesión creada exitosamente'),
              Text(
                'Los estudiantes ya pueden marcar asistencia automáticamente',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade100,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isCreatingSession = false;
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
              SesionStatusWidget(
                hasSesionActiva: _haySesionActiva,
                nombreSesion: _nombreSesionActiva,
                estudiantesPresentes: _estudiantesPresentes,
                onCerrarSesion: _isCerrandoSesion ? null : _cerrarSesion,
              ),
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
// Selector de fecha
                    DateSelectorWidget(
                      selectedDate: _fechaSeleccionada,
                      onDateChanged: _onDateChanged,
                      localeInitialized: _localeInitialized,
                    ),
                  ],
                ),
              ),
              
              Card(
  margin: const EdgeInsets.all(16),
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asistencia Automática',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Los estudiantes podrán marcar asistencia automáticamente usando GPS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isCreatingSession ? null : _crearSesionAutomatica,
            icon: _isCreatingSession
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isCreatingSession ? 'Creando sesión...' : 'Iniciar Sesión GPS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

// Y también agregar un divisor visual para separar las dos funcionalidades:
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'O registrar asistencia manual',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  ),
),

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