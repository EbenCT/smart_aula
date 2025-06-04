// lib/providers/asistencia_provider.dart
import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';
import '../services/api_service.dart';

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

  AsistenciaProvider([this._apiService]);

  List<Asistencia> get asistencias => _asistencias;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Generar clave de cache
  String _getCacheKey(int cursoId, int materiaId, DateTime fecha) {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    return '${cursoId}_${materiaId}_$fechaStr';
  }
  
  // Verificar si el cache es válido (datos frescos por 5 minutos)
  bool _isCacheFresh(String cacheKey) {
    if (!_loadTimes.containsKey(cacheKey)) return false;
    final now = DateTime.now();
    final difference = now.difference(_loadTimes[cacheKey]!);
    return difference.inMinutes < 5;
  }
  
  List<Asistencia> asistenciasPorCursoYFecha(String cursoId, DateTime fecha) {
    return _asistencias.where((a) => 
      a.cursoId == cursoId && 
      a.fecha.year == fecha.year && 
      a.fecha.month == fecha.month && 
      a.fecha.day == fecha.day
    ).toList();
  }

  void setCursoId(String cursoId) {
    if (_cursoId != cursoId) {
      _cursoId = cursoId;
      notifyListeners();
    }
  }

  void setMateriaId(int materiaId) {
    if (_materiaId != materiaId) {
      _materiaId = materiaId;
      notifyListeners();
    }
  }

  void setFechaSeleccionada(DateTime fecha) {
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
    if (_apiService == null) {
      _setError('Servicio no disponible');
      return;
    }

    final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
    
    // Verificar cache primero
    if (!forceRefresh && _isCacheFresh(cacheKey) && _cache.containsKey(cacheKey)) {
      _asistencias = List.from(_cache[cacheKey]!);
      _actualizarEstado(cursoId, materiaId, fecha);
      return;
    }

    // Evitar cargas simultáneas
    if (_isLoading) return;

    _setLoadingState(true);
    _errorMessage = null;

    try {
      final response = await _apiService!.evaluaciones.getAsistenciasMasivas(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: fecha,
      );

      final asistenciasNuevas = <Asistencia>[];

      if (response['asistencias'] != null) {
        final asistenciasBackend = response['asistencias'] as List<dynamic>;
        
        for (final asistenciaData in asistenciasBackend) {
          try {
            if (_validarDatosAsistencia(asistenciaData)) {
              final asistencia = Asistencia(
                id: asistenciaData['id'].toString(),
                estudianteId: asistenciaData['estudiante_id'].toString(),
                cursoId: materiaId.toString(),
                fecha: DateTime.parse(asistenciaData['fecha']),
                estado: _apiService!.evaluaciones.mapearEstadoDesdeBackend(asistenciaData['valor']),
                observacion: asistenciaData['descripcion'],
              );
              
              asistenciasNuevas.add(asistencia);
            }
          } catch (e) {
            // Continuar con el siguiente registro si uno falla
            debugPrint('Error procesando asistencia: $e');
          }
        }
      }

      // Actualizar cache y estado
      _cache[cacheKey] = List.from(asistenciasNuevas);
      _loadTimes[cacheKey] = DateTime.now();
      _asistencias = asistenciasNuevas;
      _actualizarEstado(cursoId, materiaId, fecha);
      
      // Limpiar cache antiguo
      _limpiarCacheAntiguo();

    } catch (e) {
      _setError(_formatError(e.toString()));
    } finally {
      _setLoadingState(false);
    }
  }

  // Validar datos de asistencia
  bool _validarDatosAsistencia(Map<String, dynamic> data) {
    return data['id'] != null && 
           data['estudiante_id'] != null && 
           data['fecha'] != null &&
           data['valor'] != null;
  }

  // Actualizar estado interno
  void _actualizarEstado(int cursoId, int materiaId, DateTime fecha) {
    _cursoId = materiaId.toString();
    _materiaId = materiaId;
    _fechaSeleccionada = fecha;
  }

  // Limpiar cache antiguo (mantener solo últimas 10 entradas)
  void _limpiarCacheAntiguo() {
    if (_cache.length > 10) {
      final sortedKeys = _loadTimes.entries
          .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remover las 5 entradas más antiguas
      for (int i = 0; i < 5 && i < sortedKeys.length; i++) {
        final keyToRemove = sortedKeys[i].key;
        _cache.remove(keyToRemove);
        _loadTimes.remove(keyToRemove);
      }
    }
  }

  // Métodos optimizados para cambios de estado
  void _setLoadingState(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
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
    final index = _asistencias.indexWhere((a) => 
      a.estudianteId == asistencia.estudianteId && 
      a.cursoId == asistencia.cursoId && 
      a.fecha.year == asistencia.fecha.year && 
      a.fecha.month == asistencia.fecha.month && 
      a.fecha.day == asistencia.fecha.day
    );
    
    if (index >= 0) {
      _asistencias[index] = asistencia;
    } else {
      _asistencias.add(asistencia);
    }
    
    // Actualizar cache local
    if (_materiaId != null) {
      final cacheKey = _getCacheKey(int.parse(asistencia.cursoId), _materiaId!, asistencia.fecha);
      _cache[cacheKey] = List.from(_asistencias);
    }
    
    notifyListeners();
  }

  void limpiarAsistencias({bool preserveCache = false}) {
    _asistencias.clear();
    _errorMessage = null;
    
    if (!preserveCache) {
      _cache.clear();
      _loadTimes.clear();
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
    
    return {
      'presentes': presentes,
      'tardanzas': tardanzas,
      'ausentes': ausentes,
      'justificados': justificados,
    };
  }

  bool get tieneCambiosPendientes => _asistencias.isNotEmpty;

  Asistencia? getAsistenciaEstudiante(String estudianteId, DateTime fecha) {
    try {
      return _asistencias.firstWhere((a) => 
        a.estudianteId == estudianteId && 
        a.fecha.year == fecha.year && 
        a.fecha.month == fecha.month && 
        a.fecha.day == fecha.day
      );
    } catch (e) {
      return null;
    }
  }

  bool tieneAsistenciasCargadas(int cursoId, int materiaId, DateTime fecha) {
    final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
    return _isCacheFresh(cacheKey) && _cache.containsKey(cacheKey);
  }

  // Invalidar cache específico
  void invalidarCache({int? cursoId, int? materiaId, DateTime? fecha}) {
    if (cursoId != null && materiaId != null && fecha != null) {
      final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
      _cache.remove(cacheKey);
      _loadTimes.remove(cacheKey);
    } else {
      _cache.clear();
      _loadTimes.clear();
    }
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'entradas': _cache.length,
    'ultimasCarga': _loadTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
    'asistenciasCargadas': _asistencias.length,
  };
}