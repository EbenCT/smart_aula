// lib/services/resumen_estudiante_api_service.dart
import './base_api_service.dart';
import './auth_service.dart';

class ResumenEstudianteApiService extends BaseApiService {
  ResumenEstudianteApiService(AuthService authService) : super(authService);

  // OBTENER RESUMEN POR ESTUDIANTE
  Future<Map<String, dynamic>> getResumenPorEstudiante({
    required int estudianteId,
    required int materiaId,
    int? periodoId,
  }) async {
    try {
      String endpoint = '/evaluaciones/resumen/por-estudiante?estudiante_id=$estudianteId&materia_id=$materiaId';
      
      if (periodoId != null) {
        endpoint += '&periodo_id=$periodoId';
      }
      
      final response = await get(endpoint);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener resumen del estudiante: $e');
    }
  }
}