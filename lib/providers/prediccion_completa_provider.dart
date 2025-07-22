// lib/providers/prediccion_completa_provider.dart
import 'package:flutter/foundation.dart';
import '../models/prediccion_completa.dart';
import '../services/api_service.dart';
import '../utils/debug_logger.dart';

class PrediccionCompletaProvider with ChangeNotifier {
  final ApiService _apiService;
  
  // Cache de predicciones por estudiante y materia
  final Map<String, List<PrediccionCompleta>> _prediccionesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Map<String, dynamic>> _estadisticasCache = {};
  
  bool _isLoading = false;
  String? _errorMessage;

  PrediccionCompletaProvider(this._apiService) {
    DebugLogger.info('PrediccionCompletaProvider inicializado', tag: 'PREDICCION_COMPLETA_PROVIDER');
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Generar clave de cache
  String _getCacheKey(int estudianteId, int materiaId, int gestionId) {
    final key = 'pred_${estudianteId}_${materiaId}_$gestionId';
    DebugLogger.info('Cache key generada: $key', tag: 'PREDICCION_COMPLETA_PROVIDER');
    return key;
  }

  // Verificar si el cache es válido (15 minutos)
  bool _isCacheFresh(String cacheKey) {
    if (!_cacheTimestamps.containsKey(cacheKey)) {
      DebugLogger.info('No hay timestamp para cache key: $cacheKey', tag: 'PREDICCION_COMPLETA_PROVIDER');
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_cacheTimestamps[cacheKey]!);
    final isFresh = difference.inMinutes < 15;
    
    DebugLogger.info('Cache $cacheKey ${isFresh ? 'es fresco' : 'ha expirado'} (${difference.inMinutes} min)', tag: 'PREDICCION_COMPLETA_PROVIDER');
    return isFresh;
  }

  // Obtener predicciones completas de un estudiante
  Future<List<PrediccionCompleta>> getPrediccionesCompletas({
    required int estudianteId,
    required int materiaId,
    int gestionId = 1,
    bool forceRefresh = false,
  }) async {
    DebugLogger.info('=== OBTENIENDO PREDICCIONES COMPLETAS ===', tag: 'PREDICCION_COMPLETA_PROVIDER');
    DebugLogger.info('Estudiante: $estudianteId, Materia: $materiaId, Gestión: $gestionId, Force: $forceRefresh', tag: 'PREDICCION_COMPLETA_PROVIDER');
    
    final cacheKey = _getCacheKey(estudianteId, materiaId, gestionId);
    
    // Verificar cache primero
    if (!forceRefresh && _isCacheFresh(cacheKey) && _prediccionesCache.containsKey(cacheKey)) {
      DebugLogger.info('Usando datos del cache', tag: 'PREDICCION_COMPLETA_PROVIDER');
      return List.from(_prediccionesCache[cacheKey]!);
    }

    // Evitar cargas simultáneas
    if (_isLoading) {
      DebugLogger.warning('Ya hay una carga en progreso, esperando...', tag: 'PREDICCION_COMPLETA_PROVIDER');
      // Esperar un poco y verificar cache nuevamente
      await Future.delayed(const Duration(milliseconds: 500));
      if (_prediccionesCache.containsKey(cacheKey)) {
        return List.from(_prediccionesCache[cacheKey]!);
      }
      throw Exception('Carga en progreso, intente nuevamente');
    }

    _setLoadingState(true);
    _errorMessage = null;

    try {
      DebugLogger.info('Llamando a API para obtener predicciones completas', tag: 'PREDICCION_COMPLETA_PROVIDER');
      
      final predicciones = await _apiService.getPrediccionesCompletas(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
      );

      DebugLogger.info('${predicciones.length} predicciones obtenidas exitosamente', tag: 'PREDICCION_COMPLETA_PROVIDER');
      
      // Guardar en cache
      _prediccionesCache[cacheKey] = List.from(predicciones);
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Limpiar cache antiguo
      _limpiarCacheAntiguo();
      
      DebugLogger.info('Predicciones almacenadas en cache', tag: 'PREDICCION_COMPLETA_PROVIDER');
      return predicciones;

    } catch (e) {
      DebugLogger.error('Error al obtener predicciones completas', tag: 'PREDICCION_COMPLETA_PROVIDER', error: e);
      _setError(_formatError(e.toString()));
      rethrow;
    } finally {
      _setLoadingState(false);
    }
  }

  // Obtener predicción de un periodo específico
  Future<PrediccionCompleta?> getPrediccionPorPeriodo({
    required int estudianteId,
    required int materiaId,
    required int periodoId,
    int gestionId = 2,
    bool forceRefresh = false,
  }) async {
    DebugLogger.info('=== OBTENIENDO PREDICCIÓN POR PERIODO ===', tag: 'PREDICCION_COMPLETA_PROVIDER');
    DebugLogger.info('Estudiante: $estudianteId, Materia: $materiaId, Periodo: $periodoId', tag: 'PREDICCION_COMPLETA_PROVIDER');
    
    try {
      final predicciones = await getPrediccionesCompletas(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
        forceRefresh: forceRefresh,
      );
      
      final prediccionPeriodo = predicciones.firstWhere(
        (p) => p.periodoId == periodoId,
        orElse: () => throw Exception('No se encontró predicción para el periodo $periodoId'),
      );
      
      DebugLogger.info('Predicción encontrada para periodo $periodoId: ${prediccionPeriodo.clasificacion}', tag: 'PREDICCION_COMPLETA_PROVIDER');
      return prediccionPeriodo;
    } catch (e) {
      DebugLogger.error('Error al obtener predicción por periodo', tag: 'PREDICCION_COMPLETA_PROVIDER', error: e);
      return null;
    }
  }

  // Obtener estadísticas de predicciones
  Future<Map<String, dynamic>> getEstadisticasPredicciones({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
    bool forceRefresh = false,
  }) async {
    DebugLogger.info('=== OBTENIENDO ESTADÍSTICAS DE PREDICCIONES ===', tag: 'PREDICCION_COMPLETA_PROVIDER');
    
    final cacheKey = _getCacheKey(estudianteId, materiaId, gestionId);
    final estadisticasCacheKey = '${cacheKey}_stats';
    
    // Verificar cache de estadísticas
    if (!forceRefresh && _isCacheFresh(estadisticasCacheKey) && _estadisticasCache.containsKey(estadisticasCacheKey)) {
      DebugLogger.info('Usando estadísticas del cache', tag: 'PREDICCION_COMPLETA_PROVIDER');
      return Map.from(_estadisticasCache[estadisticasCacheKey]!);
    }

    try {
      final estadisticas = await _apiService.getEstadisticasPredicciones(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
      );

      // Guardar estadísticas en cache
      _estadisticasCache[estadisticasCacheKey] = Map.from(estadisticas);
      _cacheTimestamps[estadisticasCacheKey] = DateTime.now();

      DebugLogger.info('Estadísticas obtenidas y almacenadas en cache', tag: 'PREDICCION_COMPLETA_PROVIDER');
      return estadisticas;

    } catch (e) {
      DebugLogger.error('Error al obtener estadísticas de predicciones', tag: 'PREDICCION_COMPLETA_PROVIDER', error: e);
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtener predicciones desde cache (sin hacer petición)
  List<PrediccionCompleta>? getPrediccionesFromCache({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) {
    final cacheKey = _getCacheKey(estudianteId, materiaId, gestionId);
    
    if (_isCacheFresh(cacheKey) && _prediccionesCache.containsKey(cacheKey)) {
      DebugLogger.info('Predicciones encontradas en cache', tag: 'PREDICCION_COMPLETA_PROVIDER');
      return List.from(_prediccionesCache[cacheKey]!);
    }
    
    DebugLogger.info('No hay predicciones en cache o han expirado', tag: 'PREDICCION_COMPLETA_PROVIDER');
    return null;
  }

  // Verificar si hay predicciones en cache
  bool hasPrediccionesInCache({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) {
    final cacheKey = _getCacheKey(estudianteId, materiaId, gestionId);
    final hasPredictions = _isCacheFresh(cacheKey) && _prediccionesCache.containsKey(cacheKey);
    
    DebugLogger.info('¿Tiene predicciones en cache? $hasPredictions', tag: 'PREDICCION_COMPLETA_PROVIDER');
    return hasPredictions;
  }

  // Obtener resumen rápido de predicciones
  Map<String, dynamic> getResumenRapido({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) {
    final predicciones = getPrediccionesFromCache(
      estudianteId: estudianteId,
      materiaId: materiaId,
      gestionId: gestionId,
    );

    if (predicciones == null || predicciones.isEmpty) {
      return {
        'tienePredicciones': false,
        'totalPeriodos': 0,
        'ultimaClasificacion': 'Sin datos',
        'promedioGeneral': 0.0,
        'tendencia': 'Sin datos',
      };
    }

    // Calcular métricas rápidas
    final totalPeriodos = predicciones.length;
    final ultimaPrediccion = predicciones.last;
    final promedioGeneral = predicciones
        .map((p) => p.resultadoNumerico)
        .reduce((a, b) => a + b) / totalPeriodos;

    // Calcular tendencia simple
    String tendencia = 'Estable';
    if (predicciones.length > 1) {
      final primera = predicciones.first.resultadoNumerico;
      final ultima = predicciones.last.resultadoNumerico;
      final diferencia = ultima - primera;
      
      if (diferencia > 5) {
        tendencia = 'Mejorando';
      } else if (diferencia < -5) {
        tendencia = 'Empeorando';
      }
    }

    final resumen = {
      'tienePredicciones': true,
      'totalPeriodos': totalPeriodos,
      'ultimaClasificacion': ultimaPrediccion.clasificacion,
      'promedioGeneral': promedioGeneral,
      'tendencia': tendencia,
      'ultimoResultado': ultimaPrediccion.resultadoNumerico,
      'colorClasificacion': ultimaPrediccion.colorClasificacion,
    };

    DebugLogger.info('Resumen rápido calculado: $resumen', tag: 'PREDICCION_COMPLETA_PROVIDER');
    return resumen;
  }

  // Limpiar cache antiguo (mantener solo últimas 10 entradas)
  void _limpiarCacheAntiguo() {
    const maxEntries = 10;
    
    if (_prediccionesCache.length > maxEntries) {
      DebugLogger.info('Limpiando cache antiguo (${_prediccionesCache.length} entradas)', tag: 'PREDICCION_COMPLETA_PROVIDER');
      
      final sortedKeys = _cacheTimestamps.entries
          .where((entry) => !entry.key.contains('_stats')) // No eliminar estadísticas
          .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remover las entradas más antiguas
      final keysToRemove = sortedKeys.take(_prediccionesCache.length - maxEntries);
      
      for (final entry in keysToRemove) {
        final keyToRemove = entry.key;
        _prediccionesCache.remove(keyToRemove);
        _cacheTimestamps.remove(keyToRemove);
        
        // También remover estadísticas relacionadas
        final statsKey = '${keyToRemove}_stats';
        _estadisticasCache.remove(statsKey);
        _cacheTimestamps.remove(statsKey);
        
        DebugLogger.info('Cache eliminado: $keyToRemove', tag: 'PREDICCION_COMPLETA_PROVIDER');
      }
    }
  }

  // Métodos optimizados para cambios de estado
  void _setLoadingState(bool loading) {
    DebugLogger.info('Cambiando estado de carga: $loading', tag: 'PREDICCION_COMPLETA_PROVIDER');
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    DebugLogger.error('Estableciendo error: $error', tag: 'PREDICCION_COMPLETA_PROVIDER');
    _errorMessage = error;
    notifyListeners();
  }

  // Formatear errores de forma concisa
  String _formatError(String error) {
    final cleanError = error.replaceFirst('Exception: ', '');
    
    if (cleanError.contains('404') || cleanError.contains('no se encontraron')) {
      return 'No hay predicciones disponibles';
    } else if (cleanError.contains('401') || cleanError.contains('autorizado')) {
      return 'Sin permisos para ver predicciones';
    } else if (cleanError.contains('timeout')) {
      return 'Conexión lenta';
    } else if (cleanError.contains('prediccion')) {
      return 'Error al cargar predicciones';
    } else if (cleanError.contains('conexión') || cleanError.contains('internet')) {
      return 'Sin conexión';
    } else {
      return cleanError.length > 50 ? '${cleanError.substring(0, 47)}...' : cleanError;
    }
  }

  // Limpiar todo el cache
  void limpiarCache() {
    DebugLogger.info('Limpiando todo el cache de predicciones', tag: 'PREDICCION_COMPLETA_PROVIDER');
    _prediccionesCache.clear();
    _cacheTimestamps.clear();
    _estadisticasCache.clear();
    notifyListeners();
  }

  // Invalidar cache específico
  void invalidarCache({int? estudianteId, int? materiaId, int? gestionId}) {
    if (estudianteId != null && materiaId != null && gestionId != null) {
      final cacheKey = _getCacheKey(estudianteId, materiaId, gestionId);
      final statsKey = '${cacheKey}_stats';
      
      _prediccionesCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      _estadisticasCache.remove(statsKey);
      _cacheTimestamps.remove(statsKey);
      
      DebugLogger.info('Cache invalidado para: $cacheKey', tag: 'PREDICCION_COMPLETA_PROVIDER');
    } else {
      limpiarCache();
    }
  }

  // Precargar predicciones en background
  Future<void> precargarPredicciones({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) async {
    if (!hasPrediccionesInCache(
      estudianteId: estudianteId,
      materiaId: materiaId,
      gestionId: gestionId,
    )) {
      try {
        DebugLogger.info('Precargando predicciones en background', tag: 'PREDICCION_COMPLETA_PROVIDER');
        
        await getPrediccionesCompletas(
          estudianteId: estudianteId,
          materiaId: materiaId,
          gestionId: gestionId,
        );
        
        DebugLogger.info('Predicciones precargadas exitosamente', tag: 'PREDICCION_COMPLETA_PROVIDER');
      } catch (e) {
        // Fallar silenciosamente en precarga
        DebugLogger.warning('Precarga de predicciones falló: $e', tag: 'PREDICCION_COMPLETA_PROVIDER');
      }
    }
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'entradas_predicciones': _prediccionesCache.length,
    'entradas_estadisticas': _estadisticasCache.length,
    'timestamps': _cacheTimestamps.map((key, value) => MapEntry(key, value.toIso8601String())),
    'claves_predicciones': _prediccionesCache.keys.toList(),
    'claves_estadisticas': _estadisticasCache.keys.toList(),
  };

  // Obtener todas las clasificaciones únicas del cache
  Set<String> get clasificacionesDisponibles {
    final clasificaciones = <String>{};
    
    for (final predicciones in _prediccionesCache.values) {
      for (final prediccion in predicciones) {
        clasificaciones.add(prediccion.clasificacion);
      }
    }
    
    return clasificaciones;
  }

  // Obtener estadísticas generales del provider
  Map<String, dynamic> get estadisticasProvider => {
    'estudiantes_con_predicciones': _prediccionesCache.length,
    'total_predicciones': _prediccionesCache.values
        .fold<int>(0, (sum, list) => sum + list.length),
    'clasificaciones_unicas': clasificacionesDisponibles.toList(),
    'cache_fresco': _prediccionesCache.keys
        .where((key) => _isCacheFresh(key))
        .length,
  };
}