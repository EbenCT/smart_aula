// lib/services/evaluacion_api_service.dart
import '../models/asistencia.dart';
import '../models/participacion.dart';
import './base_api_service.dart';
import './auth_service.dart';
import '../utils/debug_logger.dart';

class EvaluacionApiService extends BaseApiService {
  EvaluacionApiService(AuthService authService) : super(authService);

  // ASISTENCIAS
  Future<void> enviarAsistencias({
    required int docenteId,
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
    required List<Map<String, dynamic>> asistencias,
  }) async {
    DebugLogger.info('=== ENVIANDO ASISTENCIAS ===', tag: 'ASISTENCIA');
    DebugLogger.info('Docente ID: $docenteId', tag: 'ASISTENCIA');
    DebugLogger.info('Curso ID: $cursoId', tag: 'ASISTENCIA');
    DebugLogger.info('Materia ID: $materiaId', tag: 'ASISTENCIA');
    DebugLogger.info('Fecha: $fecha', tag: 'ASISTENCIA');
    DebugLogger.info('Número de asistencias: ${asistencias.length}', tag: 'ASISTENCIA');
    DebugLogger.info('Asistencias data: $asistencias', tag: 'ASISTENCIA');
    
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      DebugLogger.info('Fecha formateada: $fechaStr', tag: 'ASISTENCIA');
      
      final endpoint = '/evaluaciones/asistencia?docente_id=$docenteId&curso_id=$cursoId&materia_id=$materiaId&fecha=$fechaStr';
      DebugLogger.info('Endpoint construido: $endpoint', tag: 'ASISTENCIA');
      
      final result = await post(endpoint, asistencias);
      DebugLogger.info('Asistencias enviadas exitosamente', tag: 'ASISTENCIA');
      DebugLogger.info('Respuesta del servidor: $result', tag: 'ASISTENCIA');
      
    } catch (e) {
      DebugLogger.error('Error al enviar asistencias', tag: 'ASISTENCIA', error: e);
      throw Exception('Error al enviar asistencias: $e');
    }
  }

  // OBTENER ASISTENCIAS MASIVAS POR FECHA, CURSO Y MATERIA
  Future<Map<String, dynamic>> getAsistenciasMasivas({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
  }) async {
    DebugLogger.info('=== OBTENIENDO ASISTENCIAS MASIVAS ===', tag: 'ASISTENCIA');
    DebugLogger.info('Curso ID: $cursoId', tag: 'ASISTENCIA');
    DebugLogger.info('Materia ID: $materiaId', tag: 'ASISTENCIA');
    DebugLogger.info('Fecha: $fecha', tag: 'ASISTENCIA');
    
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      DebugLogger.info('Fecha formateada: $fechaStr', tag: 'ASISTENCIA');
      
      final endpoint = '/evaluaciones/asistencia/masiva?fecha=$fechaStr&curso_id=$cursoId&materia_id=$materiaId';
      DebugLogger.info('Endpoint construido: $endpoint', tag: 'ASISTENCIA');
      
      final response = await get(endpoint, useCache: false); // No usar cache para asistencias
      DebugLogger.info('Respuesta recibida del servidor', tag: 'ASISTENCIA');
      DebugLogger.info('Tipo de respuesta: ${response.runtimeType}', tag: 'ASISTENCIA');
      DebugLogger.info('Contenido de respuesta: $response', tag: 'ASISTENCIA');
      
      if (response is Map<String, dynamic>) {
        DebugLogger.info('Respuesta es un Map válido', tag: 'ASISTENCIA');
        
        if (response.containsKey('asistencias')) {
          final asistencias = response['asistencias'];
          DebugLogger.info('Campo asistencias encontrado, tipo: ${asistencias.runtimeType}', tag: 'ASISTENCIA');
          
          if (asistencias is List) {
            DebugLogger.info('Número de asistencias encontradas: ${asistencias.length}', tag: 'ASISTENCIA');
            
            // Log de cada asistencia individual
            for (int i = 0; i < asistencias.length && i < 3; i++) {
              DebugLogger.info('Asistencia $i: ${asistencias[i]}', tag: 'ASISTENCIA');
            }
            if (asistencias.length > 3) {
              DebugLogger.info('... y ${asistencias.length - 3} asistencias más', tag: 'ASISTENCIA');
            }
          } else {
            DebugLogger.warning('El campo asistencias no es una Lista: $asistencias', tag: 'ASISTENCIA');
          }
        } else {
          DebugLogger.warning('La respuesta no contiene el campo asistencias', tag: 'ASISTENCIA');
          DebugLogger.info('Campos disponibles: ${response.keys.toList()}', tag: 'ASISTENCIA');
        }
        
        return response;
      } else {
        DebugLogger.error('La respuesta no es un Map válido: ${response.runtimeType}', tag: 'ASISTENCIA');
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      DebugLogger.error('Error al obtener asistencias masivas', tag: 'ASISTENCIA', error: e);
      throw Exception('Error al obtener asistencias masivas: $e');
    }
  }

  Future<List<Asistencia>> getAsistenciasPorCursoYFecha(
    int cursoId,
    int materiaId,
    DateTime fecha,
  ) async {
    DebugLogger.info('=== OBTENIENDO ASISTENCIAS POR CURSO Y FECHA ===', tag: 'ASISTENCIA');
    DebugLogger.info('Curso ID: $cursoId, Materia ID: $materiaId, Fecha: $fecha', tag: 'ASISTENCIA');
    
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final endpoint = '/evaluaciones/asistencia?curso_id=$cursoId&materia_id=$materiaId&fecha=$fechaStr';
      DebugLogger.info('Endpoint: $endpoint', tag: 'ASISTENCIA');
      
      final response = await get(endpoint, useCache: false);
      DebugLogger.info('Respuesta: $response', tag: 'ASISTENCIA');
      
      if (response is List) {
        final asistencias = response.map((json) => Asistencia.fromJson(json)).toList();
        DebugLogger.info('${asistencias.length} asistencias convertidas exitosamente', tag: 'ASISTENCIA');
        return asistencias;
      } else {
        DebugLogger.error('Formato de respuesta inesperado: ${response.runtimeType}', tag: 'ASISTENCIA');
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      DebugLogger.error('Error al obtener asistencias', tag: 'ASISTENCIA', error: e);
      throw Exception('Error al obtener asistencias: $e');
    }
  }

  // PARTICIPACIONES
  Future<void> enviarParticipaciones({
    required int docenteId,
    required int cursoId,
    required int materiaId,
    required int periodoId,
    required DateTime fecha,
    required List<Map<String, dynamic>> participaciones,
  }) async {
    DebugLogger.info('=== ENVIANDO PARTICIPACIONES ===', tag: 'PARTICIPACION');
    DebugLogger.info('Docente ID: $docenteId', tag: 'PARTICIPACION');
    DebugLogger.info('Curso ID: $cursoId', tag: 'PARTICIPACION');
    DebugLogger.info('Materia ID: $materiaId', tag: 'PARTICIPACION');
    DebugLogger.info('Periodo ID: $periodoId', tag: 'PARTICIPACION');
    DebugLogger.info('Fecha: $fecha', tag: 'PARTICIPACION');
    DebugLogger.info('Número de participaciones: ${participaciones.length}', tag: 'PARTICIPACION');
    DebugLogger.info('Participaciones data: $participaciones', tag: 'PARTICIPACION');
    
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      DebugLogger.info('Fecha formateada: $fechaStr', tag: 'PARTICIPACION');
      
      final endpoint = '/evaluaciones/participacion?docente_id=$docenteId&curso_id=$cursoId&materia_id=$materiaId&periodo_id=$periodoId&fecha=$fechaStr';
      DebugLogger.info('Endpoint construido: $endpoint', tag: 'PARTICIPACION');
      
      final result = await post(endpoint, participaciones);
      DebugLogger.info('Participaciones enviadas exitosamente', tag: 'PARTICIPACION');
      DebugLogger.info('Respuesta del servidor: $result', tag: 'PARTICIPACION');
      
    } catch (e) {
      DebugLogger.error('Error al enviar participaciones', tag: 'PARTICIPACION', error: e);
      throw Exception('Error al enviar participaciones: $e');
    }
  }

  // OBTENER PARTICIPACIONES MASIVAS POR FECHA, CURSO Y MATERIA
  Future<Map<String, dynamic>> getParticipacionesMasivas({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
  }) async {
    DebugLogger.info('=== OBTENIENDO PARTICIPACIONES MASIVAS ===', tag: 'PARTICIPACION');
    DebugLogger.info('Curso ID: $cursoId', tag: 'PARTICIPACION');
    DebugLogger.info('Materia ID: $materiaId', tag: 'PARTICIPACION');
    DebugLogger.info('Fecha: $fecha', tag: 'PARTICIPACION');
    
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      DebugLogger.info('Fecha formateada: $fechaStr', tag: 'PARTICIPACION');
      
      // tipo_evaluacion_id=4 corresponde a participaciones según tu endpoint
      final endpoint = '/evaluaciones/evaluacion/masiva?fecha=$fechaStr&curso_id=$cursoId&materia_id=$materiaId&tipo_evaluacion_id=4';
      DebugLogger.info('Endpoint construido: $endpoint', tag: 'PARTICIPACION');
      
      final response = await get(endpoint, useCache: false);
      DebugLogger.info('Respuesta recibida del servidor', tag: 'PARTICIPACION');
      DebugLogger.info('Tipo de respuesta: ${response.runtimeType}', tag: 'PARTICIPACION');
      DebugLogger.info('Contenido de respuesta: $response', tag: 'PARTICIPACION');
      
      if (response is Map<String, dynamic>) {
        DebugLogger.info('Respuesta es un Map válido', tag: 'PARTICIPACION');
        
        if (response.containsKey('evaluaciones')) {
          final evaluaciones = response['evaluaciones'];
          DebugLogger.info('Campo evaluaciones encontrado, tipo: ${evaluaciones.runtimeType}', tag: 'PARTICIPACION');
          
          if (evaluaciones is List) {
            DebugLogger.info('Número de participaciones encontradas: ${evaluaciones.length}', tag: 'PARTICIPACION');
            
            // Log de cada participación individual
            for (int i = 0; i < evaluaciones.length && i < 3; i++) {
              DebugLogger.info('Participación $i: ${evaluaciones[i]}', tag: 'PARTICIPACION');
            }
            if (evaluaciones.length > 3) {
              DebugLogger.info('... y ${evaluaciones.length - 3} participaciones más', tag: 'PARTICIPACION');
            }
          } else {
            DebugLogger.warning('El campo evaluaciones no es una Lista: $evaluaciones', tag: 'PARTICIPACION');
          }
        } else {
          DebugLogger.warning('La respuesta no contiene el campo evaluaciones', tag: 'PARTICIPACION');
          DebugLogger.info('Campos disponibles: ${response.keys.toList()}', tag: 'PARTICIPACION');
        }
        
        return response;
      } else {
        DebugLogger.error('La respuesta no es un Map válido: ${response.runtimeType}', tag: 'PARTICIPACION');
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      DebugLogger.error('Error al obtener participaciones masivas', tag: 'PARTICIPACION', error: e);
      throw Exception('Error al obtener participaciones masivas: $e');
    }
  }

  Future<List<Participacion>> getParticipacionesPorEstudiante(
    int estudianteId,
    int cursoId,
    int materiaId,
    {DateTime? fechaInicio, DateTime? fechaFin}
  ) async {
    DebugLogger.info('=== OBTENIENDO PARTICIPACIONES POR ESTUDIANTE ===', tag: 'PARTICIPACION');
    DebugLogger.info('Estudiante ID: $estudianteId, Curso ID: $cursoId, Materia ID: $materiaId', tag: 'PARTICIPACION');
    
    try {
      String endpoint = '/estudiantes/$estudianteId/participaciones?curso_id=$cursoId&materia_id=$materiaId';
      
      if (fechaInicio != null) {
        final fechaInicioStr = '${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}';
        endpoint += '&fecha_inicio=$fechaInicioStr';
      }
      
      if (fechaFin != null) {
        final fechaFinStr = '${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}';
        endpoint += '&fecha_fin=$fechaFinStr';
      }
      
      DebugLogger.info('Endpoint: $endpoint', tag: 'PARTICIPACION');
      
      final response = await get(endpoint, useCache: false);
      DebugLogger.info('Respuesta: $response', tag: 'PARTICIPACION');
      
      if (response is List) {
        final participaciones = response.map((json) => Participacion.fromJson(json)).toList();
        DebugLogger.info('${participaciones.length} participaciones convertidas exitosamente', tag: 'PARTICIPACION');
        return participaciones;
      } else {
        DebugLogger.error('Formato de respuesta inesperado: ${response.runtimeType}', tag: 'PARTICIPACION');
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      DebugLogger.error('Error al obtener participaciones', tag: 'PARTICIPACION', error: e);
      throw Exception('Error al obtener participaciones: $e');
    }
  }

  // Mapear estados de asistencia del backend al modelo local
  EstadoAsistencia mapearEstadoDesdeBackend(dynamic valor) {
    DebugLogger.info('Mapeando estado desde backend: $valor (tipo: ${valor.runtimeType})', tag: 'MAPPER');
    
    // Convertir a int si viene como double
    final valorInt = valor is double ? valor.toInt() : valor as int;
    
    EstadoAsistencia estado;
    switch (valorInt) {
      case 100:
        estado = EstadoAsistencia.presente;
        break;
      case 50:
        estado = EstadoAsistencia.tardanza;
        break;
      case 0:
        estado = EstadoAsistencia.ausente;
        break;
      case 75:
        estado = EstadoAsistencia.justificado;
        break;
      default:
        DebugLogger.warning('Valor de asistencia desconocido: $valorInt, usando ausente por defecto', tag: 'MAPPER');
        estado = EstadoAsistencia.ausente;
        break;
    }
    
    DebugLogger.info('Estado mapeado: $estado', tag: 'MAPPER');
    return estado;
  }

  // Mapear estados de asistencia al formato del backend
  String mapearEstadoAsistencia(EstadoAsistencia estado) {
    DebugLogger.info('Mapeando estado a backend: $estado', tag: 'MAPPER');
    
    String resultado;
    switch (estado) {
      case EstadoAsistencia.presente:
        resultado = 'presente';
        break;
      case EstadoAsistencia.ausente:
        resultado = 'falta';
        break;
      case EstadoAsistencia.tardanza:
        resultado = 'tarde';
        break;
      case EstadoAsistencia.justificado:
        resultado = 'justificacion';
        break;
    }
    
    DebugLogger.info('Estado mapeado para backend: $resultado', tag: 'MAPPER');
    return resultado;
  }

  // Mapear estado de asistencia a valor numérico para el backend
  int mapearEstadoAValor(EstadoAsistencia estado) {
    DebugLogger.info('Mapeando estado a valor numérico: $estado', tag: 'MAPPER');
    
    int valor;
    switch (estado) {
      case EstadoAsistencia.presente:
        valor = 100;
        break;
      case EstadoAsistencia.tardanza:
        valor = 50;
        break;
      case EstadoAsistencia.ausente:
        valor = 0;
        break;
      case EstadoAsistencia.justificado:
        valor = 75;
        break;
    }
    
    DebugLogger.info('Valor numérico mapeado: $valor', tag: 'MAPPER');
    return valor;
  }
}