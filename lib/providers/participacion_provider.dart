// lib/providers/participacion_provider.dart
import 'package:flutter/foundation.dart';
import '../models/participacion.dart';
import '../services/api_service.dart';
import '../utils/debug_logger.dart';

class ParticipacionProvider with ChangeNotifier {
  final ApiService? _apiService;
  
  List<Participacion> _participaciones = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _cursoId;
  int? _materiaId;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Cache para optimizar cargas
  final Map<String, DateTime> _loadTimes = {};
  final Map<String, List<Participacion>> _cache = {};

  ParticipacionProvider([this._apiService]) {
    DebugLogger.info('ParticipacionProvider inicializado', tag: 'PARTICIPACION_PROVIDER');
  }

  List<Participacion> get participaciones => _participaciones;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Generar clave de cache
  String _getCacheKey(int cursoId, int materiaId, DateTime fecha) {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final key = 'part_${cursoId}_${materiaId}_$fechaStr';
    DebugLogger.info('Cache key generada: $key', tag: 'PARTICIPACION_PROVIDER');
    return key;
  }
  
  // Verificar si el cache es válido (datos frescos por 5 minutos)
  bool _isCacheFresh(String cacheKey) {
    if (!_loadTimes.containsKey(cacheKey)) {
      DebugLogger.info('No hay timestamp para cache key: $cacheKey', tag: 'PARTICIPACION_PROVIDER');
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_loadTimes[cacheKey]!);
    final isFresh = difference.inMinutes < 5;
    
    DebugLogger.info('Cache $cacheKey ${isFresh ? 'es fresco' : 'ha expirado'} (${difference.inMinutes} min)', tag: 'PARTICIPACION_PROVIDER');
    return isFresh;
  }
  
  List<Participacion> participacionesPorCursoYFecha(String cursoId, DateTime fecha) {
    final filtradas = _participaciones.where((p) => 
      p.cursoId == cursoId && 
      p.fecha.year == fecha.year && 
      p.fecha.month == fecha.month && 
      p.fecha.day == fecha.day
    ).toList();
    
    DebugLogger.info('Participaciones filtradas para curso $cursoId y fecha $fecha: ${filtradas.length}', tag: 'PARTICIPACION_PROVIDER');
    return filtradas;
  }

  void setCursoId(String cursoId) {
    DebugLogger.info('Estableciendo curso ID: $cursoId', tag: 'PARTICIPACION_PROVIDER');
    if (_cursoId != cursoId) {
      _cursoId = cursoId;
      notifyListeners();
    }
  }

  void setMateriaId(int materiaId) {
    DebugLogger.info('Estableciendo materia ID: $materiaId', tag: 'PARTICIPACION_PROVIDER');
    if (_materiaId != materiaId) {
      _materiaId = materiaId;
      notifyListeners();
    }
  }

  void setFechaSeleccionada(DateTime fecha) {
    DebugLogger.info('Estableciendo fecha seleccionada: $fecha', tag: 'PARTICIPACION_PROVIDER');
    if (_fechaSeleccionada != fecha) {
      _fechaSeleccionada = fecha;
      notifyListeners();
    }
  }

  // Cargar participaciones desde el backend con optimización
  Future<void> cargarParticipacionesDesdeBackend({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
    bool forceRefresh = false,
  }) async {
    DebugLogger.info('=== INICIANDO CARGA DE PARTICIPACIONES ===', tag: 'PARTICIPACION_PROVIDER');
    DebugLogger.info('Parámetros - Curso: $cursoId, Materia: $materiaId, Fecha: $fecha, Force: $forceRefresh', tag: 'PARTICIPACION_PROVIDER');
    
    if (_apiService == null) {
      DebugLogger.error('ApiService es null', tag: 'PARTICIPACION_PROVIDER');
      _setError('Servicio no disponible');
      return;
    }

    final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
    
    // Verificar cache primero
    if (!forceRefresh && _isCacheFresh(cacheKey) && _cache.containsKey(cacheKey)) {
      DebugLogger.info('Usando datos del cache', tag: 'PARTICIPACION_PROVIDER');
      _participaciones = List.from(_cache[cacheKey]!);
      _actualizarEstado(cursoId, materiaId, fecha);
      return;
    }

    // Evitar cargas simultáneas
    if (_isLoading) {
      DebugLogger.warning('Ya hay una carga en progreso, ignorando nueva solicitud', tag: 'PARTICIPACION_PROVIDER');
      return;
    }

    _setLoadingState(true);
    _errorMessage = null;

    try {
      DebugLogger.info('Llamando a API para obtener participaciones masivas', tag: 'PARTICIPACION_PROVIDER');
      
      final response = await _apiService.evaluaciones.getParticipacionesMasivas(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: fecha,
      );

      DebugLogger.info('Respuesta recibida de API', tag: 'PARTICIPACION_PROVIDER');
      DebugLogger.info('Tipo de respuesta: ${response.runtimeType}', tag: 'PARTICIPACION_PROVIDER');

      final participacionesNuevas = <Participacion>[];

      if (response['evaluaciones'] != null) {
        final participacionesBackend = response['evaluaciones'] as List<dynamic>;
        DebugLogger.info('Procesando ${participacionesBackend.length} participaciones del backend', tag: 'PARTICIPACION_PROVIDER');
        
        for (int i = 0; i < participacionesBackend.length; i++) {
          final participacionData = participacionesBackend[i];
          DebugLogger.info('Procesando participación $i: $participacionData', tag: 'PARTICIPACION_PROVIDER');
          
          try {
            if (_validarDatosParticipacion(participacionData)) {
              DebugLogger.info('Datos válidos, creando objeto Participacion', tag: 'PARTICIPACION_PROVIDER');
              
              final participacion = Participacion(
                id: participacionData['id'].toString(),
                estudianteId: participacionData['estudiante_id'].toString(),
                cursoId: materiaId.toString(),
                fecha: DateTime.parse(participacionData['fecha']),
                valoracion: (participacionData['valor'] is double) 
                    ? (participacionData['valor'] as double).toInt() 
                    : (participacionData['valor'] as int),
                descripcion: participacionData['descripcion'] ?? 'Participación',
                tipo: TipoParticipacion.comentario,
              );
              
              participacionesNuevas.add(participacion);
              DebugLogger.info('Participación agregada exitosamente para estudiante: ${participacion.estudianteId}', tag: 'PARTICIPACION_PROVIDER');
            } else {
              DebugLogger.warning('Datos de participación inválidos: $participacionData', tag: 'PARTICIPACION_PROVIDER');
            }
          } catch (e) {
            DebugLogger.error('Error procesando participación individual $i', tag: 'PARTICIPACION_PROVIDER', error: e);
            DebugLogger.error('Datos problemáticos: $participacionData', tag: 'PARTICIPACION_PROVIDER');
          }
        }
      } else {
        DebugLogger.warning('No se encontró campo evaluaciones en la respuesta', tag: 'PARTICIPACION_PROVIDER');
        DebugLogger.info('Respuesta completa: $response', tag: 'PARTICIPACION_PROVIDER');
      }

      // Actualizar cache y estado
      DebugLogger.info('Actualizando cache con ${participacionesNuevas.length} participaciones', tag: 'PARTICIPACION_PROVIDER');
      _cache[cacheKey] = List.from(participacionesNuevas);
      _loadTimes[cacheKey] = DateTime.now();
      _participaciones = participacionesNuevas;
      _actualizarEstado(cursoId, materiaId, fecha);
      
      // Limpiar cache antiguo
      _limpiarCacheAntiguo();

      DebugLogger.info('Carga de participaciones completada exitosamente', tag: 'PARTICIPACION_PROVIDER');

    } catch (e) {
      DebugLogger.error('Error al cargar participaciones desde backend', tag: 'PARTICIPACION_PROVIDER', error: e);
      _setError(_formatError(e.toString()));
    } finally {
      _setLoadingState(false);
    }
  }

  // Validar datos de participación
  bool _validarDatosParticipacion(Map<String, dynamic> data) {
    final esValido = data['id'] != null && 
           data['estudiante_id'] != null && 
           data['fecha'] != null &&
           data['valor'] != null;
    
    DebugLogger.info('Validación de datos: $esValido', tag: 'PARTICIPACION_PROVIDER');
    if (!esValido) {
      DebugLogger.warning('Datos faltantes en: $data', tag: 'PARTICIPACION_PROVIDER');
    }
    
    return esValido;
  }

  // Actualizar estado interno
  void _actualizarEstado(int cursoId, int materiaId, DateTime fecha) {
    DebugLogger.info('Actualizando estado interno', tag: 'PARTICIPACION_PROVIDER');
    _cursoId = materiaId.toString();
    _materiaId = materiaId;
    _fechaSeleccionada = fecha;
  }

  // Limpiar cache antiguo (mantener solo últimas 10 entradas)
  void _limpiarCacheAntiguo() {
    if (_cache.length > 10) {
      DebugLogger.info('Limpiando cache antiguo (${_cache.length} entradas)', tag: 'PARTICIPACION_PROVIDER');
      
      final sortedKeys = _loadTimes.entries
          .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remover las 5 entradas más antiguas
      for (int i = 0; i < 5 && i < sortedKeys.length; i++) {
        final keyToRemove = sortedKeys[i].key;
        _cache.remove(keyToRemove);
        _loadTimes.remove(keyToRemove);
        DebugLogger.info('Cache eliminado: $keyToRemove', tag: 'PARTICIPACION_PROVIDER');
      }
    }
  }

  // Métodos optimizados para cambios de estado
  void _setLoadingState(bool loading) {
    DebugLogger.info('Cambiando estado de carga: $loading', tag: 'PARTICIPACION_PROVIDER');
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    DebugLogger.error('Estableciendo error: $error', tag: 'PARTICIPACION_PROVIDER');
    _errorMessage = _formatError(error);
    notifyListeners();
  }

  // Formatear errores de forma concisa
  String _formatError(String error) {
    final cleanError = error.replaceFirst('Exception: ', '');
    
    if (cleanError.contains('timeout')) {
      return 'Conexión lenta';
    } else if (cleanError.contains('participacion')) {
      return 'Error al cargar participaciones';
    } else if (cleanError.contains('conexión') || cleanError.contains('internet')) {
      return 'Sin conexión';
    } else {
      return cleanError.length > 40 ? '${cleanError.substring(0, 37)}...' : cleanError;
    }
  }

  void registrarParticipacion(Participacion participacion) {
    DebugLogger.info('Registrando participación para estudiante ${participacion.estudianteId}', tag: 'PARTICIPACION_PROVIDER');
    
    final index = _participaciones.indexWhere((p) => 
      p.estudianteId == participacion.estudianteId && 
      p.cursoId == participacion.cursoId && 
      p.fecha.year == participacion.fecha.year && 
      p.fecha.month == participacion.fecha.month && 
      p.fecha.day == participacion.fecha.day
    );
    
    if (index >= 0) {
      DebugLogger.info('Actualizando participación existente en índice $index', tag: 'PARTICIPACION_PROVIDER');
      _participaciones[index] = participacion;
    } else {
      DebugLogger.info('Agregando nueva participación', tag: 'PARTICIPACION_PROVIDER');
      _participaciones.add(participacion);
    }
    
    // Actualizar cache local
    if (_materiaId != null) {
      final cacheKey = _getCacheKey(int.parse(participacion.cursoId), _materiaId!, participacion.fecha);
      _cache[cacheKey] = List.from(_participaciones);
      DebugLogger.info('Cache local actualizado', tag: 'PARTICIPACION_PROVIDER');
    }
    
    notifyListeners();
  }

  void limpiarParticipaciones({bool preserveCache = false}) {
    DebugLogger.info('Limpiando participaciones (preserveCache: $preserveCache)', tag: 'PARTICIPACION_PROVIDER');
    
    _participaciones.clear();
    _errorMessage = null;
    
    if (!preserveCache) {
      _cache.clear();
      _loadTimes.clear();
      DebugLogger.info('Cache limpiado completamente', tag: 'PARTICIPACION_PROVIDER');
    }
    
    notifyListeners();
  }

  // Obtener estadísticas optimizadas
  Map<String, dynamic> getEstadisticasParticipacion(String cursoId, DateTime fecha) {
    final participacionesFecha = participacionesPorCursoYFecha(cursoId, fecha);
    
    final participacionesConValor = participacionesFecha.where((p) => p.valoracion > 0).toList();
    final totalPuntaje = participacionesConValor.fold<int>(0, (sum, p) => sum + p.valoracion);
    final promedioPuntaje = participacionesConValor.isNotEmpty ? totalPuntaje / participacionesConValor.length : 0.0;
    
    final stats = {
      'total': participacionesFecha.length,
      'conParticipacion': participacionesConValor.length,
      'sinParticipacion': participacionesFecha.where((p) => p.valoracion == 0).length,
      'promedioPuntaje': promedioPuntaje,
    };
    
    DebugLogger.info('Estadísticas calculadas: $stats', tag: 'PARTICIPACION_PROVIDER');
    return stats;
  }

  bool get tieneCambiosPendientes => _participaciones.isNotEmpty;

  Participacion? getParticipacionEstudiante(String estudianteId, DateTime fecha) {
    try {
      final participacion = _participaciones.firstWhere((p) => 
        p.estudianteId == estudianteId && 
        p.fecha.year == fecha.year && 
        p.fecha.month == fecha.month && 
        p.fecha.day == fecha.day
      );
      DebugLogger.info('Participación encontrada para estudiante $estudianteId: ${participacion.valoracion}', tag: 'PARTICIPACION_PROVIDER');
      return participacion;
    } catch (e) {
      DebugLogger.info('No se encontró participación para estudiante $estudianteId', tag: 'PARTICIPACION_PROVIDER');
      return null;
    }
  }

  bool tieneParticipacionesCargadas(int cursoId, int materiaId, DateTime fecha) {
    final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
    final tieneDatos = _isCacheFresh(cacheKey) && _cache.containsKey(cacheKey);
    DebugLogger.info('¿Tiene participaciones cargadas? $tieneDatos', tag: 'PARTICIPACION_PROVIDER');
    return tieneDatos;
  }

  // Obtener todas las participaciones de un estudiante para la fecha seleccionada
  List<Participacion> getParticipacionesEstudiante(String estudianteId, DateTime fecha) {
    final participaciones = _participaciones.where((p) => 
      p.estudianteId == estudianteId && 
      p.fecha.year == fecha.year && 
      p.fecha.month == fecha.month && 
      p.fecha.day == fecha.day
    ).toList();
    
    DebugLogger.info('Participaciones encontradas para estudiante $estudianteId: ${participaciones.length}', tag: 'PARTICIPACION_PROVIDER');
    return participaciones;
  }

  // Eliminar participación específica
  void eliminarParticipacion(Participacion participacion) {
    DebugLogger.info('Eliminando participación: ${participacion.id}', tag: 'PARTICIPACION_PROVIDER');
    
    if (_participaciones.remove(participacion)) {
      // Actualizar cache local
      if (_materiaId != null) {
        final cacheKey = _getCacheKey(int.parse(participacion.cursoId), _materiaId!, participacion.fecha);
        _cache[cacheKey] = List.from(_participaciones);
        DebugLogger.info('Cache actualizado después de eliminar participación', tag: 'PARTICIPACION_PROVIDER');
      }
      notifyListeners();
    }
  }

  // Actualizar participación existente
  void actualizarParticipacion(Participacion participacionAnterior, Participacion participacionNueva) {
    DebugLogger.info('Actualizando participación: ${participacionAnterior.id} -> ${participacionNueva.id}', tag: 'PARTICIPACION_PROVIDER');
    
    final index = _participaciones.indexOf(participacionAnterior);
    if (index >= 0) {
      _participaciones[index] = participacionNueva;
      
      // Actualizar cache local
      if (_materiaId != null) {
        final cacheKey = _getCacheKey(int.parse(participacionNueva.cursoId), _materiaId!, participacionNueva.fecha);
        _cache[cacheKey] = List.from(_participaciones);
        DebugLogger.info('Cache actualizado después de modificar participación', tag: 'PARTICIPACION_PROVIDER');
      }
      
      notifyListeners();
    }
  }

  // Invalidar cache específico
  void invalidarCache({int? cursoId, int? materiaId, DateTime? fecha}) {
    if (cursoId != null && materiaId != null && fecha != null) {
      final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
      _cache.remove(cacheKey);
      _loadTimes.remove(cacheKey);
      DebugLogger.info('Cache invalidado para: $cacheKey', tag: 'PARTICIPACION_PROVIDER');
    } else {
      _cache.clear();
      _loadTimes.clear();
      DebugLogger.info('Todo el cache invalidado', tag: 'PARTICIPACION_PROVIDER');
    }
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'entradas': _cache.length,
    'ultimasCarga': _loadTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
    'participacionesCargadas': _participaciones.length,
  };
}