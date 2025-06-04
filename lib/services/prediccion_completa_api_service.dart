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
    int gestionId = 1, // Siempre será 1 según tu especificación
  }) async {
    DebugLogger.info('=== OBTENIENDO PREDICCIONES COMPLETAS ===', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Estudiante ID: $estudianteId', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Materia ID: $materiaId', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Gestión ID: $gestionId', tag: 'PREDICCION_COMPLETA');
    
    try {
      final endpoint = '/ml/estudiante/$estudianteId/materia/$materiaId/gestion/$gestionId/predicciones-completas';
      DebugLogger.info('Endpoint construido: $endpoint', tag: 'PREDICCION_COMPLETA');
      
      final response = await get(endpoint, useCache: true, cacheMinutes: 10);
      DebugLogger.info('Respuesta recibida del servidor', tag: 'PREDICCION_COMPLETA');
      DebugLogger.info('Tipo de respuesta: ${response.runtimeType}', tag: 'PREDICCION_COMPLETA');
      
      if (response is Map<String, dynamic>) {
        DebugLogger.info('Respuesta es un Map válido', tag: 'PREDICCION_COMPLETA');
        
        final success = response['success'] ?? false;
        final mensaje = response['mensaje'] ?? '';
        
        DebugLogger.info('Success: $success', tag: 'PREDICCION_COMPLETA');
        DebugLogger.info('Mensaje: $mensaje', tag: 'PREDICCION_COMPLETA');
        
        if (success && response.containsKey('data')) {
          final data = response['data'];
          DebugLogger.info('Campo data encontrado, tipo: ${data.runtimeType}', tag: 'PREDICCION_COMPLETA');
          
          if (data is List) {
            DebugLogger.info('Número de predicciones encontradas: ${data.length}', tag: 'PREDICCION_COMPLETA');
            
            final predicciones = <PrediccionCompleta>[];
            
            for (int i = 0; i < data.length; i++) {
              try {
                final prediccionData = data[i] as Map<String, dynamic>;
                DebugLogger.info('Procesando predicción $i: periodo ${prediccionData['periodo_nombre']}', tag: 'PREDICCION_COMPLETA');
                
                final prediccion = PrediccionCompleta.fromJson(prediccionData);
                predicciones.add(prediccion);
                
                DebugLogger.info('Predicción $i procesada: ${prediccion.clasificacion} (${prediccion.resultadoNumerico})', tag: 'PREDICCION_COMPLETA');
              } catch (e) {
                DebugLogger.error('Error procesando predicción $i', tag: 'PREDICCION_COMPLETA', error: e);
                DebugLogger.error('Datos problemáticos: ${data[i]}', tag: 'PREDICCION_COMPLETA');
              }
            }
            
            DebugLogger.info('${predicciones.length} predicciones procesadas exitosamente', tag: 'PREDICCION_COMPLETA');
            return predicciones;
          } else {
            DebugLogger.error('El campo data no es una Lista: $data', tag: 'PREDICCION_COMPLETA');
            throw Exception('Formato de datos inesperado');
          }
        } else {
          DebugLogger.warning('La respuesta no indica éxito o no contiene datos', tag: 'PREDICCION_COMPLETA');
          DebugLogger.info('Success: $success, tiene data: ${response.containsKey('data')}', tag: 'PREDICCION_COMPLETA');
          
          if (!success) {
            throw Exception(mensaje.isNotEmpty ? mensaje : 'Error al obtener predicciones');
          } else {
            // Si success es true pero no hay data, devolver lista vacía
            DebugLogger.info('Success true pero sin data, devolviendo lista vacía', tag: 'PREDICCION_COMPLETA');
            return [];
          }
        }
      } else {
        DebugLogger.error('La respuesta no es un Map válido: ${response.runtimeType}', tag: 'PREDICCION_COMPLETA');
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      DebugLogger.error('Error al obtener predicciones completas', tag: 'PREDICCION_COMPLETA', error: e);
      
      // Manejar errores específicos
      if (e.toString().contains('404')) {
        throw Exception('No se encontraron predicciones para este estudiante');
      } else if (e.toString().contains('401')) {
        throw Exception('No autorizado para ver predicciones');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado al obtener predicciones');
      } else if (e.toString().contains('conexión') || e.toString().contains('internet')) {
        throw Exception('Error de conexión al obtener predicciones');
      } else {
        throw Exception('Error al obtener predicciones: $e');
      }
    }
  }

  // OBTENER PREDICCIÓN ESPECÍFICA DE UN PERIODO
  Future<PrediccionCompleta?> getPrediccionPorPeriodo({
    required int estudianteId,
    required int materiaId,
    required int periodoId,
    int gestionId = 1,
  }) async {
    DebugLogger.info('=== OBTENIENDO PREDICCIÓN POR PERIODO ===', tag: 'PREDICCION_COMPLETA');
    DebugLogger.info('Estudiante: $estudianteId, Materia: $materiaId, Periodo: $periodoId', tag: 'PREDICCION_COMPLETA');
    
    try {
      final predicciones = await getPrediccionesCompletas(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
      );
      
      final prediccionPeriodo = predicciones.firstWhere(
        (p) => p.periodoId == periodoId,
        orElse: () => throw Exception('No se encontró predicción para el periodo $periodoId'),
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
    int gestionId = 1,
  }) async {
    DebugLogger.info('=== CALCULANDO ESTADÍSTICAS DE PREDICCIONES ===', tag: 'PREDICCION_COMPLETA');
    
    try {
      final predicciones = await getPrediccionesCompletas(
        estudianteId: estudianteId,
        materiaId: materiaId,
        gestionId: gestionId,
      );
      
      if (predicciones.isEmpty) {
        return {
          'total_predicciones': 0,
          'promedio_resultado': 0.0,
          'tendencia': 'Sin datos',
          'clasificacion_mas_frecuente': 'Sin datos',
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
      
      final clasificacionMasFrecuente = contadorClasificaciones.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      final estadisticas = {
        'total_predicciones': totalPredicciones,
        'promedio_resultado': promedioResultado,
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
}