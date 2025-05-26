// lib/services/evaluacion_api_service.dart
import '../models/asistencia.dart';
import '../models/participacion.dart';
import './base_api_service.dart';
import './auth_service.dart';

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
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      
      final endpoint = '/evaluaciones/asistencia?docente_id=$docenteId&curso_id=$cursoId&materia_id=$materiaId&fecha=$fechaStr';
      
      await post(endpoint, asistencias);
    } catch (e) {
      throw Exception('Error al enviar asistencias: $e');
    }
  }

  // OBTENER ASISTENCIAS MASIVAS POR FECHA, CURSO Y MATERIA
  Future<Map<String, dynamic>> getAsistenciasMasivas({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
  }) async {
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final endpoint = '/evaluaciones/asistencia/masiva?fecha=$fechaStr&curso_id=$cursoId&materia_id=$materiaId';
      
      final response = await get(endpoint);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener asistencias masivas: $e');
    }
  }

  Future<List<Asistencia>> getAsistenciasPorCursoYFecha(
    int cursoId,
    int materiaId,
    DateTime fecha,
  ) async {
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final response = await get('/evaluaciones/asistencia?curso_id=$cursoId&materia_id=$materiaId&fecha=$fechaStr');
      
      if (response is List) {
        return response.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
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
    try {
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      
      final endpoint = '/evaluaciones/participacion?docente_id=$docenteId&curso_id=$cursoId&materia_id=$materiaId&periodo_id=$periodoId&fecha=$fechaStr';
      
      await post(endpoint, participaciones);
    } catch (e) {
      throw Exception('Error al enviar participaciones: $e');
    }
  }

  Future<List<Participacion>> getParticipacionesPorEstudiante(
    int estudianteId,
    int cursoId,
    int materiaId,
    {DateTime? fechaInicio, DateTime? fechaFin}
  ) async {
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
      
      final response = await get(endpoint);
      
      if (response is List) {
        return response.map((json) => Participacion.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener participaciones: $e');
    }
  }

  // Mapear estados de asistencia del backend al modelo local
  EstadoAsistencia mapearEstadoDesdeBackend(dynamic valor) {
    // Convertir a int si viene como double
    final valorInt = valor is double ? valor.toInt() : valor as int;
    
    switch (valorInt) {
      case 100:
        return EstadoAsistencia.presente;
      case 50:
        return EstadoAsistencia.tardanza;
      case 0:
        return EstadoAsistencia.ausente;
      case 75:
        return EstadoAsistencia.justificado;
      default:
        return EstadoAsistencia.ausente;
    }
  }

  // Mapear estados de asistencia al formato del backend
  String mapearEstadoAsistencia(EstadoAsistencia estado) {
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

  // Mapear estado de asistencia a valor numérico para el backend
  int mapearEstadoAValor(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 100;
      case EstadoAsistencia.tardanza:
        return 50;
      case EstadoAsistencia.ausente:
        return 0;
      case EstadoAsistencia.justificado:
        return 75;
    }
  }
}