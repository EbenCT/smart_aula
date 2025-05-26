// lib/services/resumen_api_service.dart
import './base_api_service.dart';
import './auth_service.dart';

class ResumenApiService extends BaseApiService {
  ResumenApiService(AuthService authService) : super(authService);

  // OBTENER RESUMEN COMPLETO DE MATERIA
  Future<Map<String, dynamic>> getResumenMateriaCompleto(
    int cursoId, 
    int materiaId
  ) async {
    try {
      final endpoint = '/resumen/materia/completo?curso_id=$cursoId&materia_id=$materiaId';
      final response = await get(endpoint);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener resumen de materia: $e');
    }
  }

  // OBTENER RESUMEN POR PERIODO ESPECÍFICO
  Future<Map<String, dynamic>> getResumenMateriaPorPeriodo(
    int cursoId, 
    int materiaId,
    int periodoId
  ) async {
    try {
      final endpoint = '/resumen/materia/completo?curso_id=$cursoId&materia_id=$materiaId&periodo_id=$periodoId';
      final response = await get(endpoint);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener resumen de materia por periodo: $e');
    }
  }
}