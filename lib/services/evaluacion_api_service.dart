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
}