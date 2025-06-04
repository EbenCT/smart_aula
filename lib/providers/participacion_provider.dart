// lib/providers/participacion_provider.dart
import 'package:flutter/foundation.dart';
import '../models/participacion.dart';
import '../services/api_service.dart';

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

  ParticipacionProvider([this._apiService]);

  List<Participacion> get participaciones => _participaciones;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Generar clave de cache
  String _getCacheKey(int cursoId, int materiaId, DateTime fecha) {
    final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    return 'part_${cursoId}_${materiaId}_$fechaStr';
  }
  
  // Verificar si el cache es válido (datos frescos por 5 minutos)
  bool _isCacheFresh(String cacheKey) {
    if (!_loadTimes.containsKey(cacheKey)) return false;
    final now = DateTime.now();
    final difference = now.difference(_loadTimes[cacheKey]!);
    return difference.inMinutes < 5;
  }
  
  List<Participacion> participacionesPorCursoYFecha(String cursoId, DateTime fecha) {
    return _participaciones.where((p) => 
      p.cursoId == cursoId && 
      p.fecha.year == fecha.year && 
      p.fecha.month == fecha.month && 
      p.fecha.day == fecha.day
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

  // Cargar participaciones desde el backend con optimización
  Future<void> cargarParticipacionesDesdeBackend({
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
      _participaciones = List.from(_cache[cacheKey]!);
      _actualizarEstado(cursoId, materiaId, fecha);
      return;
    }

    // Evitar cargas simultáneas
    if (_isLoading) return;

    _setLoadingState(true);
    _errorMessage = null;

    try {
      final response = await _apiService!.evaluaciones.getParticipacionesMasivas(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: fecha,
      );

      final participacionesNuevas = <Participacion>[];

      if (response['evaluaciones'] != null) {
        final participacionesBackend = response['evaluaciones'] as List<dynamic>;
        
        for (final participacionData in participacionesBackend) {
          try {
            if (_validarDatosParticipacion(participacionData)) {
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
            }
          } catch (e) {
            // Continuar con el siguiente registro si uno falla
            debugPrint('Error procesando participación: $e');
          }
        }
      }

      // Actualizar cache y estado
      _cache[cacheKey] = List.from(participacionesNuevas);
      _loadTimes[cacheKey] = DateTime.now();
      _participaciones = participacionesNuevas;
      _actualizarEstado(cursoId, materiaId, fecha);
      
      // Limpiar cache antiguo
      _limpiarCacheAntiguo();

    } catch (e) {
      _setError(_formatError(e.toString()));
    } finally {
      _setLoadingState(false);
    }
  }

  // Validar datos de participación
  bool _validarDatosParticipacion(Map<String, dynamic> data) {
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
    } else if (cleanError.contains('participacion')) {
      return 'Error al cargar participaciones';
    } else if (cleanError.contains('conexión') || cleanError.contains('internet')) {
      return 'Sin conexión';
    } else {
      return cleanError.length > 40 ? '${cleanError.substring(0, 37)}...' : cleanError;
    }
  }

  void registrarParticipacion(Participacion participacion) {
    final index = _participaciones.indexWhere((p) => 
      p.estudianteId == participacion.estudianteId && 
      p.cursoId == participacion.cursoId && 
      p.fecha.year == participacion.fecha.year && 
      p.fecha.month == participacion.fecha.month && 
      p.fecha.day == participacion.fecha.day
    );
    
    if (index >= 0) {
      _participaciones[index] = participacion;
    } else {
      _participaciones.add(participacion);
    }
    
    // Actualizar cache local
    if (_materiaId != null) {
      final cacheKey = _getCacheKey(int.parse(participacion.cursoId), _materiaId!, participacion.fecha);
      _cache[cacheKey] = List.from(_participaciones);
    }
    
    notifyListeners();
  }

  void limpiarParticipaciones({bool preserveCache = false}) {
    _participaciones.clear();
    _errorMessage = null;
    
    if (!preserveCache) {
      _cache.clear();
      _loadTimes.clear();
    }
    
    notifyListeners();
  }

  // Obtener estadísticas optimizadas
  Map<String, dynamic> getEstadisticasParticipacion(String cursoId, DateTime fecha) {
    final participacionesFecha = participacionesPorCursoYFecha(cursoId, fecha);
    
    final participacionesConValor = participacionesFecha.where((p) => p.valoracion > 0).toList();
    final totalPuntaje = participacionesConValor.fold<int>(0, (sum, p) => sum + p.valoracion);
    final promedioPuntaje = participacionesConValor.isNotEmpty ? totalPuntaje / participacionesConValor.length : 0.0;
    
    return {
      'total': participacionesFecha.length,
      'conParticipacion': participacionesConValor.length,
      'sinParticipacion': participacionesFecha.where((p) => p.valoracion == 0).length,
      'promedioPuntaje': promedioPuntaje,
    };
  }

  bool get tieneCambiosPendientes => _participaciones.isNotEmpty;

  Participacion? getParticipacionEstudiante(String estudianteId, DateTime fecha) {
    try {
      return _participaciones.firstWhere((p) => 
        p.estudianteId == estudianteId && 
        p.fecha.year == fecha.year && 
        p.fecha.month == fecha.month && 
        p.fecha.day == fecha.day
      );
    } catch (e) {
      return null;
    }
  }

  bool tieneParticipacionesCargadas(int cursoId, int materiaId, DateTime fecha) {
    final cacheKey = _getCacheKey(cursoId, materiaId, fecha);
    return _isCacheFresh(cacheKey) && _cache.containsKey(cacheKey);
  }

  // Obtener todas las participaciones de un estudiante para la fecha seleccionada
  List<Participacion> getParticipacionesEstudiante(String estudianteId, DateTime fecha) {
    return _participaciones.where((p) => 
      p.estudianteId == estudianteId && 
      p.fecha.year == fecha.year && 
      p.fecha.month == fecha.month && 
      p.fecha.day == fecha.day
    ).toList();
  }

  // Eliminar participación específica
  void eliminarParticipacion(Participacion participacion) {
    if (_participaciones.remove(participacion)) {
      // Actualizar cache local
      if (_materiaId != null) {
        final cacheKey = _getCacheKey(int.parse(participacion.cursoId), _materiaId!, participacion.fecha);
        _cache[cacheKey] = List.from(_participaciones);
      }
      notifyListeners();
    }
  }

  // Actualizar participación existente
  void actualizarParticipacion(Participacion participacionAnterior, Participacion participacionNueva) {
    final index = _participaciones.indexOf(participacionAnterior);
    if (index >= 0) {
      _participaciones[index] = participacionNueva;
      
      // Actualizar cache local
      if (_materiaId != null) {
        final cacheKey = _getCacheKey(int.parse(participacionNueva.cursoId), _materiaId!, participacionNueva.fecha);
        _cache[cacheKey] = List.from(_participaciones);
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
    } else {
      _cache.clear();
      _loadTimes.clear();
    }
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'entradas': _cache.length,
    'ultimasCarga': _loadTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
    'participacionesCargadas': _participaciones.length,
  };
}