// lib/providers/asistencia_provider.dart
import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';
import '../services/api_service.dart';
import '../utils/debug_logger.dart';

class AsistenciaProvider with ChangeNotifier {
  final ApiService? _apiService;
  
  List<Asistencia> _asistencias = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _cursoId;
  int? _materiaId;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Cache para evitar cargas múltiples
  final Map<String, DateTime> _loadTimes = {};
  final Map<String, List<Asistencia>> _cache = {};

  AsistenciaProvider([this._apiService]) {
    DebugLogger.info('AsistenciaProvider inicializado', tag: 'ASISTENCIA_PROVIDER');
  }

  List<Asistencia> get asistencias => _asistencias;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Generar clave de cache
  String _getCacheKey(int cursoId, int materiaId, DateTime fecha) {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final key = '${cursoId}_${materiaId}_$fechaStr';
    DebugLogger.info('Cache key generada: $key', tag: 'ASISTENCIA_PROVIDER');
    return key;
  }
  
  // Verificar si el cache es válido (datos frescos por 5 minutos)
  bool _isCacheFresh(String cacheKey) {
    if (!_loadTimes.containsKey(cacheKey)) {
      DebugLogger.info('No hay timestamp para cache key: $cacheKey', tag: 'ASISTENCIA_PROVIDER');
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_loadTimes[cacheKey]!);
    final isFresh = difference.inMinutes < 5;
    
    DebugLogger.info('Cache $cacheKey ${isFresh ? 'es fresco' : 'ha expirado'} (${difference.inMinutes} min)', tag: 'ASISTENCIA_PROVIDER');
    return isFresh;
  }
  
  List<Asistencia> asistenciasPorCursoYFecha(String cursoId, DateTime fecha) {
    final filtradas = _asistencias.where((a) => 
      a.cursoId == cursoId && 
      a.fecha.year == fecha.year && 
      a.fecha.month == fecha.month && 
      a.fecha.day == fecha.day
    ).toList();
    
    DebugLogger.info('Asistencias filtradas para curso $cursoId y fecha $fecha: ${filtradas.length}', tag: 'ASISTENCIA_PROVIDER');
    return filtradas;
  }

  void setCursoId(String cursoId) {
    DebugLogger.info('Estableciendo curso ID: $cursoId', tag: 'ASISTENCIA_PROVIDER');
    if (_cursoId != cursoId) {
      _cursoId = cursoId;
      notifyListeners();
    }
  }

  void setMateriaId(int materiaId) {
    DebugLogger.info('Estableciendo materia ID: $materiaId', tag: 'ASISTENCIA_PROVIDER');
    if (_materiaId != materiaId) {
      _materiaId = materiaId;
      notifyListeners();
    }
  }

  void setFechaSeleccionada(DateTime fecha) {
    DebugLogger.info('Estableciendo fecha seleccionada: $fecha', tag: 'ASISTENCIA_PROVIDER');
    if (_fechaSeleccionada != fecha) {
      _fechaSeleccionada = fecha;
      notifyListeners();
    }
  }

  // Cargar asistencias desde el backend con optimización
  Future<void> cargarAsistenciasDesdeBackend({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
    bool forceRefresh = false,
  }) async {
    DebugLogger.info('=== INICIANDO CARGA DE ASISTENCIAS ===', tag: 'ASISTENCIA_PROVIDER');
    DebugLogger.info('Parámetros - Curso: $cursoId, Materia: $materiaId, Fecha: $fecha, Force: $forceRefresh', tag: 'ASISTENCIA_PROVIDER');
    
    if (_apiService == null) {
      DebugLogger.error('ApiService es null', tag: 'ASISTENCIA_PROVIDER');
      _setError('Servicio no disponible');
      return;
    }

    final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
    
    // Verificar cache primero
    if (!forceRefresh && _isCacheFresh(cacheKey) && _cache.containsKey(cacheKey)) {
      DebugLogger.info('Usando datos del cache', tag: 'ASISTENCIA_PROVIDER');
      _asistencias = List.from(_cache[cacheKey]!);
      _actualizarEstado(cursoId, materiaId, fecha);
      return;
    }

    // Evitar cargas simultáneas
    if (_isLoading) {
      DebugLogger.warning('Ya hay una carga en progreso, ignorando nueva solicitud', tag: 'ASISTENCIA_PROVIDER');
      return;
    }

    _setLoadingState(true);
    _errorMessage = null;

    try {
      DebugLogger.info('Llamando a API para obtener asistencias masivas', tag: 'ASISTENCIA_PROVIDER');
      
      final response = await _apiService.evaluaciones.getAsistenciasMasivas(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: fecha,
      );

      DebugLogger.info('Respuesta recibida de API', tag: 'ASISTENCIA_PROVIDER');
      DebugLogger.info('Tipo de respuesta: ${response.runtimeType}', tag: 'ASISTENCIA_PROVIDER');

      final asistenciasNuevas = <Asistencia>[];

      if (response['asistencias'] != null) {
        final asistenciasBackend = response['asistencias'] as List<dynamic>;
        DebugLogger.info('Procesando ${asistenciasBackend.length} asistencias del backend', tag: 'ASISTENCIA_PROVIDER');
        
        for (int i = 0; i < asistenciasBackend.length; i++) {
          final asistenciaData = asistenciasBackend[i];
          DebugLogger.info('Procesando asistencia $i: $asistenciaData', tag: 'ASISTENCIA_PROVIDER');
          
          try {
            if (_validarDatosAsistencia(asistenciaData)) {
              DebugLogger.info('Datos válidos, creando objeto Asistencia', tag: 'ASISTENCIA_PROVIDER');
              
              final asistencia = Asistencia(
                id: asistenciaData['id'].toString(),
                estudianteId: asistenciaData['estudiante_id'].toString(),
                cursoId: materiaId.toString(),
                fecha: DateTime.parse(asistenciaData['fecha']),
                estado: _apiService.evaluaciones.mapearEstadoDesdeBackend(asistenciaData['valor']),
                observacion: asistenciaData['descripcion'],
              );
              
              asistenciasNuevas.add(asistencia);
              DebugLogger.info('Asistencia agregada exitosamente para estudiante: ${asistencia.estudianteId}', tag: 'ASISTENCIA_PROVIDER');
            } else {
              DebugLogger.warning('Datos de asistencia inválidos: $asistenciaData', tag: 'ASISTENCIA_PROVIDER');
            }
          } catch (e) {
            DebugLogger.error('Error procesando asistencia individual $i', tag: 'ASISTENCIA_PROVIDER', error: e);
            DebugLogger.error('Datos problemáticos: $asistenciaData', tag: 'ASISTENCIA_PROVIDER');
          }
        }
      } else {
        DebugLogger.warning('No se encontró campo asistencias en la respuesta', tag: 'ASISTENCIA_PROVIDER');
        DebugLogger.info('Respuesta completa: $response', tag: 'ASISTENCIA_PROVIDER');
      }

      // Actualizar cache y estado
      DebugLogger.info('Actualizando cache con ${asistenciasNuevas.length} asistencias', tag: 'ASISTENCIA_PROVIDER');
      _cache[cacheKey] = List.from(asistenciasNuevas);
      _loadTimes[cacheKey] = DateTime.now();
      _asistencias = asistenciasNuevas;
      _actualizarEstado(cursoId, materiaId, fecha);
      
      // Limpiar cache antiguo
      _limpiarCacheAntiguo();

      DebugLogger.info('Carga de asistencias completada exitosamente', tag: 'ASISTENCIA_PROVIDER');

    } catch (e) {
      DebugLogger.error('Error al cargar asistencias desde backend', tag: 'ASISTENCIA_PROVIDER', error: e);
      _setError(_formatError(e.toString()));
    } finally {
      _setLoadingState(false);
    }
  }

  // Validar datos de asistencia
  bool _validarDatosAsistencia(Map<String, dynamic> data) {
    final esValido = data['id'] != null && 
           data['estudiante_id'] != null && 
           data['fecha'] != null &&
           data['valor'] != null;
    
    DebugLogger.info('Validación de datos: $esValido', tag: 'ASISTENCIA_PROVIDER');
    if (!esValido) {
      DebugLogger.warning('Datos faltantes en: $data', tag: 'ASISTENCIA_PROVIDER');
    }
    
    return esValido;
  }

  // Actualizar estado interno
  void _actualizarEstado(int cursoId, int materiaId, DateTime fecha) {
    DebugLogger.info('Actualizando estado interno', tag: 'ASISTENCIA_PROVIDER');
    _cursoId = materiaId.toString();
    _materiaId = materiaId;
    _fechaSeleccionada = fecha;
  }

  // Limpiar cache antiguo (mantener solo últimas 10 entradas)
  void _limpiarCacheAntiguo() {
    if (_cache.length > 10) {
      DebugLogger.info('Limpiando cache antiguo (${_cache.length} entradas)', tag: 'ASISTENCIA_PROVIDER');
      
      final sortedKeys = _loadTimes.entries
          .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remover las 5 entradas más antiguas
      for (int i = 0; i < 5 && i < sortedKeys.length; i++) {
        final keyToRemove = sortedKeys[i].key;
        _cache.remove(keyToRemove);
        _loadTimes.remove(keyToRemove);
        DebugLogger.info('Cache eliminado: $keyToRemove', tag: 'ASISTENCIA_PROVIDER');
      }
    }
  }

  // Métodos optimizados para cambios de estado
  void _setLoadingState(bool loading) {
    DebugLogger.info('Cambiando estado de carga: $loading', tag: 'ASISTENCIA_PROVIDER');
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    DebugLogger.error('Estableciendo error: $error', tag: 'ASISTENCIA_PROVIDER');
    _errorMessage = _formatError(error);
    notifyListeners();
  }

  // Formatear errores de forma concisa
  String _formatError(String error) {
    final cleanError = error.replaceFirst('Exception: ', '');
    
    if (cleanError.contains('timeout')) {
      return 'Conexión lenta';
    } else if (cleanError.contains('asistencia')) {
      return 'Error al cargar asistencias';
    } else if (cleanError.contains('conexión') || cleanError.contains('internet')) {
      return 'Sin conexión';
    } else {
      return cleanError.length > 40 ? '${cleanError.substring(0, 37)}...' : cleanError;
    }
  }

  void registrarAsistencia(Asistencia asistencia) {
    DebugLogger.info('Registrando asistencia para estudiante ${asistencia.estudianteId}', tag: 'ASISTENCIA_PROVIDER');
    
    final index = _asistencias.indexWhere((a) => 
      a.estudianteId == asistencia.estudianteId && 
      a.cursoId == asistencia.cursoId && 
      a.fecha.year == asistencia.fecha.year && 
      a.fecha.month == asistencia.fecha.month && 
      a.fecha.day == asistencia.fecha.day
    );
    
    if (index >= 0) {
      DebugLogger.info('Actualizando asistencia existente en índice $index', tag: 'ASISTENCIA_PROVIDER');
      _asistencias[index] = asistencia;
    } else {
      DebugLogger.info('Agregando nueva asistencia', tag: 'ASISTENCIA_PROVIDER');
      _asistencias.add(asistencia);
    }
    
    // Actualizar cache local
    if (_materiaId != null) {
      final cacheKey = _getCacheKey(int.parse(asistencia.cursoId), _materiaId!, asistencia.fecha);
      _cache[cacheKey] = List.from(_asistencias);
      DebugLogger.info('Cache local actualizado', tag: 'ASISTENCIA_PROVIDER');
    }
    
    notifyListeners();
  }

  void limpiarAsistencias({bool preserveCache = false}) {
    DebugLogger.info('Limpiando asistencias (preserveCache: $preserveCache)', tag: 'ASISTENCIA_PROVIDER');
    
    _asistencias.clear();
    _errorMessage = null;
    
    if (!preserveCache) {
      _cache.clear();
      _loadTimes.clear();
      DebugLogger.info('Cache limpiado completamente', tag: 'ASISTENCIA_PROVIDER');
    }
    
    notifyListeners();
  }

  // Obtener estadísticas optimizadas
  Map<String, int> getEstadisticasAsistencia(String cursoId, DateTime fecha) {
    final asistenciasFecha = asistenciasPorCursoYFecha(cursoId, fecha);
    
    int presentes = 0, tardanzas = 0, ausentes = 0, justificados = 0;
    
    for (final asistencia in asistenciasFecha) {
      switch (asistencia.estado) {
        case EstadoAsistencia.presente:
          presentes++;
          break;
        case EstadoAsistencia.tardanza:
          tardanzas++;
          break;
        case EstadoAsistencia.ausente:
          ausentes++;
          break;
        case EstadoAsistencia.justificado:
          justificados++;
          break;
      }
    }
    
    final stats = {
      'presentes': presentes,
      'tardanzas': tardanzas,
      'ausentes': ausentes,
      'justificados': justificados,
    };
    
    DebugLogger.info('Estadísticas calculadas: $stats', tag: 'ASISTENCIA_PROVIDER');
    return stats;
  }

  bool get tieneCambiosPendientes => _asistencias.isNotEmpty;

  Asistencia? getAsistenciaEstudiante(String estudianteId, DateTime fecha) {
    try {
      final asistencia = _asistencias.firstWhere((a) => 
        a.estudianteId == estudianteId && 
        a.fecha.year == fecha.year && 
        a.fecha.month == fecha.month && 
        a.fecha.day == fecha.day
      );
      DebugLogger.info('Asistencia encontrada para estudiante $estudianteId: ${asistencia.estado}', tag: 'ASISTENCIA_PROVIDER');
      return asistencia;
    } catch (e) {
      DebugLogger.info('No se encontró asistencia para estudiante $estudianteId', tag: 'ASISTENCIA_PROVIDER');
      return null;
    }
  }

  bool tieneAsistenciasCargadas(int cursoId, int materiaId, DateTime fecha) {
    final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
    final tieneDatos = _isCacheFresh(cacheKey) && _cache.containsKey(cacheKey);
    DebugLogger.info('¿Tiene asistencias cargadas? $tieneDatos', tag: 'ASISTENCIA_PROVIDER');
    return tieneDatos;
  }

  // Invalidar cache específico
  void invalidarCache({int? cursoId, int? materiaId, DateTime? fecha}) {
    if (cursoId != null && materiaId != null && fecha != null) {
      final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
      _cache.remove(cacheKey);
      _loadTimes.remove(cacheKey);
      DebugLogger.info('Cache invalidado para: $cacheKey', tag: 'ASISTENCIA_PROVIDER');
    } else {
      _cache.clear();
      _loadTimes.clear();
      DebugLogger.info('Todo el cache invalidado', tag: 'ASISTENCIA_PROVIDER');
    }
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'entradas': _cache.length,
    'ultimasCarga': _loadTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
    'asistenciasCargadas': _asistencias.length,
  };
}