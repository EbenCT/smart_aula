// lib/services/prediccion_api_service.dart
import '../models/prediccion.dart';
import './base_api_service.dart';
import './auth_service.dart';

class PrediccionApiService extends BaseApiService {
  PrediccionApiService(AuthService authService) : super(authService);

  // OBTENER PREDICCIONES POR CURSO Y MATERIA
  Future<List<Prediccion>> getPrediccionesPorCursoYMateria(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      String endpoint = '/predicciones?curso_id=$cursoId&materia_id=$materiaId';
      
      if (periodoId != null) {
        endpoint += '&periodo_id=$periodoId';
      }
      
      final response = await get(endpoint);
      
      if (response is List) {
        return response.map((json) => Prediccion.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener predicciones: $e');
    }
  }

  // OBTENER PREDICCIÓN DE UN ESTUDIANTE ESPECÍFICO
  Future<Prediccion?> getPrediccionEstudiante(
    int estudianteId, 
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      String endpoint = '/estudiantes/$estudianteId/prediccion?curso_id=$cursoId&materia_id=$materiaId';
      
      if (periodoId != null) {
        endpoint += '&periodo_id=$periodoId';
      }
      
      final response = await get(endpoint);
      
      if (response != null) {
        return Prediccion.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener predicción del estudiante: $e');
    }
  }

  // GENERAR PREDICCIONES PARA UN CURSO
  Future<void> generarPredicciones(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      final data = {
        'curso_id': cursoId,
        'materia_id': materiaId,
        if (periodoId != null) 'periodo_id': periodoId,
      };
      
      await post('/predicciones/generar', data);
    } catch (e) {
      throw Exception('Error al generar predicciones: $e');
    }
  }

  // ESTADÍSTICAS GENERALES DEL DASHBOARD
  Future<Map<String, dynamic>> getEstadisticasDashboard(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      String endpoint = '/dashboard/estadisticas?curso_id=$cursoId&materia_id=$materiaId';
      
      if (periodoId != null) {
        endpoint += '&periodo_id=$periodoId';
      }
      
      final response = await get(endpoint);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener estadísticas del dashboard: $e');
    }
  }

  // ESTUDIANTES EN RIESGO
  Future<List<Map<String, dynamic>>> getEstudiantesEnRiesgo(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      String endpoint = '/dashboard/estudiantes-riesgo?curso_id=$cursoId&materia_id=$materiaId';
      
      if (periodoId != null) {
        endpoint += '&periodo_id=$periodoId';
      }
      
      final response = await get(endpoint);
      
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener estudiantes en riesgo: $e');
    }
  }

  // DISTRIBUCIÓN DE RENDIMIENTO
  Future<Map<String, int>> getDistribucionRendimiento(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      String endpoint = '/dashboard/distribucion-rendimiento?curso_id=$cursoId&materia_id=$materiaId';
      
      if (periodoId != null) {
        endpoint += '&periodo_id=$periodoId';
      }
      
      final response = await get(endpoint);
      return Map<String, int>.from(response);
    } catch (e) {
      throw Exception('Error al obtener distribución de rendimiento: $e');
    }
  }

  // TENDENCIAS DE ASISTENCIA
  Future<List<Map<String, dynamic>>> getTendenciasAsistencia(
    int cursoId, 
    int materiaId,
    {int? periodoId, DateTime? fechaInicio, DateTime? fechaFin}
  ) async {
    try {
      String endpoint = '/dashboard/tendencias-asistencia?curso_id=$cursoId&materia_id=$materiaId';
      
      if (periodoId != null) {
        endpoint += '&periodo_id=$periodoId';
      }
      
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
        return List<Map<String, dynamic>>.from(response);
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener tendencias de asistencia: $e');
    }
  }
}