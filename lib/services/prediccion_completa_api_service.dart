// lib/services/prediccion_completa_api_service.dart
import '../models/prediccion_completa.dart';
import './base_api_service.dart';
import './auth_service.dart';
import '../utils/debug_logger.dart';

class PrediccionCompletaApiService extends BaseApiService {
  PrediccionCompletaApiService(AuthService authService) : super(authService);

  // OBTENER PREDICCIONES COMPLETAS DE UN ESTUDIANTE
  Future<List<PrediccionCompleta>> getPrediccionesCompletas({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2, // Siempre será 1 según tu especificación
  }) async {
    DebugLogger.info('=== OBTENIENDO PREDICCIONES COMPLETAS ===', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Estudiante ID: $estudianteId', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Materia ID: $materiaId', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Gestión ID: $gestionId', tag: 'PREDICCION_COMPLETA');
    
    try {
      // NUEVO ENDPOINT CON QUERY PARAMETERS
      final endpoint = '/ml/predicciones-completas?estudiante_id=$estudianteId&materia_id=$materiaId&gestion_id=$gestionId';
      DebugLogger.info('Endpoint actualizado: $endpoint', tag: 'PREDICCION_COMPLETA');
      
      final response = await get(endpoint, useCache: true, cacheMinutes: 10);
      DebugLogger.info('Respuesta recibida del servidor', tag: 'PREDICCION_COMPLETA');
      DebugLogger.info('Tipo de respuesta: ${response.runtimeType}', tag: 'PREDICCION_COMPLETA');
      
      if (response is Map<String, dynamic>) {
        DebugLogger.info('Respuesta es un Map válido', tag: 'PREDICCION_COMPLETA');
        
        final success = response['success'] ?? false;
        final mensaje = response['mensaje'] ?? '';
        
        if (success) {
          DebugLogger.info('Predicciones obtenidas exitosamente', tag: 'PREDICCION_COMPLETA');
          final data = response['data'] as List<dynamic>? ?? [];
          
          final predicciones = data.map((json) => PrediccionCompleta.fromJson(json)).toList();
          DebugLogger.info('${predicciones.length} predicciones convertidas', tag: 'PREDICCION_COMPLETA');
          
          return predicciones;
        } else {
          DebugLogger.warning('Respuesta no exitosa: $mensaje', tag: 'PREDICCION_COMPLETA');
          
          // Si success es false pero no hay error crítico, devolver lista vacía
          if (mensaje.toLowerCase().contains('no se encontraron') || 
              mensaje.toLowerCase().contains('no existen')) {
            DebugLogger.info('No se encontraron predicciones, devolviendo lista vacía', tag: 'PREDICCION_COMPLETA');
            return [];
          } else {
            throw Exception('Error del servidor: $mensaje');
          }
        }
      } else if (response is List) {
        DebugLogger.info('Respuesta es una lista directa', tag: 'PREDICCION_COMPLETA');
        final predicciones = response.map((json) => PrediccionCompleta.fromJson(json)).toList();
        DebugLogger.info('${predicciones.length} predicciones convertidas desde lista', tag: 'PREDICCION_COMPLETA');
        return predicciones;
      } else {
        DebugLogger.error('Formato de respuesta inesperado: ${response.runtimeType}', tag: 'PREDICCION_COMPLETA');
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      DebugLogger.error('Error obteniendo predicciones completas', tag: 'PREDICCION_COMPLETA', error: e);
      
      // Manejo de errores específicos
      if (e.toString().contains('404')) {
        throw Exception('No se encontraron predicciones para este estudiante');
      } else if (e.toString().contains('401')) {
        throw Exception('No autorizado para ver predicciones');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado al obtener predicciones');
      } else if (e.toString().contains('conexión') || e.toString().contains('internet')) {
        throw Exception('Error de conexión al obtener predicciones');
      } else {
        throw Exception('Error al obtener predicciones completas: $e');
      }
    }
  }

  // OBTENER PREDICCIÓN ESPECÍFICA DE UN PERIODO
  Future<PrediccionCompleta?> getPrediccionPorPeriodo({
    required int estudianteId,
    required int materiaId,
    required int periodoId,
    int gestionId = 2,
  }) async {
    DebugLogger.info('=== OBTENIENDO PREDICCIÓN POR PERIODO ===', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Estudiante: $estudianteId, Materia: $materiaId, Periodo: $periodoId', tag: 'PREDICCION_COMPLETA');
    
    try {
      final predicciones = await getPrediccionesCompletas(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
      );
      
      if (predicciones.isEmpty) {
        DebugLogger.warning('No hay predicciones disponibles', tag: 'PREDICCION_COMPLETA');
        return null;
      }
      
      final prediccionPeriodo = predicciones.firstWhere(
        (p) => p.periodoId == periodoId,
        orElse: () {
          DebugLogger.warning('No se encontró predicción para el periodo $periodoId', tag: 'PREDICCION_COMPLETA');
          throw Exception('No se encontró predicción para el periodo $periodoId');
        },
      );
      
      DebugLogger.info('Predicción encontrada para periodo $periodoId: ${prediccionPeriodo.clasificacion}', tag: 'PREDICCION_COMPLETA');
      return prediccionPeriodo;
    } catch (e) {
      DebugLogger.error('Error al obtener predicción por periodo', tag: 'PREDICCION_COMPLETA', error: e);
      return null;
    }
  }

  // OBTENER ESTADÍSTICAS DE PREDICCIONES
  Future<Map<String, dynamic>> getEstadisticasPredicciones({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) async {
    DebugLogger.info('=== CALCULANDO ESTADÍSTICAS DE PREDICCIONES ===', tag: 'PREDICCION_COMPLETA');
    
    try {
      final predicciones = await getPrediccionesCompletas(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
      );
      
      if (predicciones.isEmpty) {
        DebugLogger.warning('No hay predicciones para calcular estadísticas', tag: 'PREDICCION_COMPLETA');
        return {
          'total_predicciones': 0,
          'promedio_resultado': 0.0,
          'tendencia': 'Sin datos',
          'clasificacion_mas_frecuente': 'Sin datos',
          'predicciones_por_clasificacion': <String, int>{},
        };
      }
      
      // Calcular estadísticas
      final totalPredicciones = predicciones.length;
      final promedioResultado = predicciones
          .map((p) => p.resultadoNumerico)
          .reduce((a, b) => a + b) / totalPredicciones;
      
      // Calcular tendencia (comparar primera y última predicción)
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
      
      // Clasificación más frecuente
      final clasificaciones = predicciones.map((p) => p.clasificacion).toList();
      final contadorClasificaciones = <String, int>{};
      
      for (final clasificacion in clasificaciones) {
        contadorClasificaciones[clasificacion] = (contadorClasificaciones[clasificacion] ?? 0) + 1;
      }
      
      final clasificacionMasFrecuente = contadorClasificaciones.isNotEmpty
          ? contadorClasificaciones.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : 'Sin datos';
      
      final estadisticas = {
        'total_predicciones': totalPredicciones,
        'promedio_resultado': double.parse(promedioResultado.toStringAsFixed(2)),
        'tendencia': tendencia,
        'clasificacion_mas_frecuente': clasificacionMasFrecuente,
        'predicciones_por_clasificacion': contadorClasificaciones,
      };
      
      DebugLogger.info('Estadísticas calculadas: $estadisticas', tag: 'PREDICCION_COMPLETA');
      return estadisticas;
    } catch (e) {
      DebugLogger.error('Error al calcular estadísticas', tag: 'PREDICCION_COMPLETA', error: e);
      throw Exception('Error al calcular estadísticas de predicciones: $e');
    }
  }

  // MÉTODO PARA LIMPIAR CACHÉ DE PREDICCIONES
  Future<void> limpiarCachePredicciones() async {
    try {
      DebugLogger.info('Limpiando caché de predicciones', tag: 'PREDICCION_COMPLETA');
      // Si tienes un método para limpiar caché específico, úsalo aquí
      // await clearCache('/ml/predicciones-completas');
    } catch (e) {
      DebugLogger.error('Error limpiando caché', tag: 'PREDICCION_COMPLETA', error: e);
    }
  }

  // MÉTODO PARA REFRESCAR PREDICCIONES (sin caché)
  Future<List<PrediccionCompleta>> refrescarPrediccionesCompletas({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) async {
    DebugLogger.info('=== REFRESCANDO PREDICCIONES COMPLETAS ===', tag: 'PREDICCION_COMPLETA');
    
    try {
      final endpoint = '/ml/predicciones-completas?estudiante_id=$estudianteId&materia_id=$materiaId&gestion_id=$gestionId';
      DebugLogger.info('Endpoint para refrescar: $endpoint', tag: 'PREDICCION_COMPLETA');
      
      // Sin caché para obtener datos frescos
      final response = await get(endpoint, useCache: false);
      DebugLogger.info('Respuesta fresca recibida', tag: 'PREDICCION_COMPLETA');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final mensaje = response['mensaje'] ?? '';
        
        if (success) {
          final data = response['data'] as List<dynamic>? ?? [];
          final predicciones = data.map((json) => PrediccionCompleta.fromJson(json)).toList();
          DebugLogger.info('${predicciones.length} predicciones refrescadas', tag: 'PREDICCION_COMPLETA');
          return predicciones;
        } else {
          if (mensaje.toLowerCase().contains('no se encontraron') || 
              mensaje.toLowerCase().contains('no existen')) {
            DebugLogger.info('No se encontraron predicciones al refrescar', tag: 'PREDICCION_COMPLETA');
            return [];
          } else {
            throw Exception('Error del servidor: $mensaje');
          }
        }
      } else if (response is List) {
        final predicciones = response.map((json) => PrediccionCompleta.fromJson(json)).toList();
        DebugLogger.info('${predicciones.length} predicciones refrescadas desde lista', tag: 'PREDICCION_COMPLETA');
        return predicciones;
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      DebugLogger.error('Error refrescando predicciones', tag: 'PREDICCION_COMPLETA', error: e);
      throw Exception('Error al refrescar predicciones: $e');
    }
  }

  // VERIFICAR SI HAY PREDICCIONES DISPONIBLES
  Future<bool> tienePrediccionesDisponibles({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) async {
    try {
      final predicciones = await getPrediccionesCompletas(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
      );
      return predicciones.isNotEmpty;
    } catch (e) {
      DebugLogger.error('Error verificando disponibilidad de predicciones', tag: 'PREDICCION_COMPLETA', error: e);
      return false;
    }
  }
}