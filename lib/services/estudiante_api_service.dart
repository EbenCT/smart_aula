// lib/services/estudiante_api_service.dart
import '../models/estudiante.dart';
import './base_api_service.dart';
import './auth_service.dart';

class EstudianteApiService extends BaseApiService {
  final AuthService _authService;
  
  EstudianteApiService(this._authService) : super(_authService);

  // ESTUDIANTES POR MATERIA
  Future<List<Estudiante>> getEstudiantesPorMateria(int cursoId, int materiaId) async {
    try {
      final userId = _authService.usuario?.id ?? _authService.userId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await get('/docentes/alumnos-docente/$userId/curso/$cursoId/materia/$materiaId');
      
      if (response is List) {
        return response.map((json) => Estudiante.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener los estudiantes: $e');
    }
  }

  // OBTENER ESTUDIANTE POR ID
  Future<Estudiante> getEstudiantePorId(int estudianteId) async {
    try {
      final response = await get('/estudiantes/$estudianteId');
      return Estudiante.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener el estudiante: $e');
    }
  }

  // ACTUALIZAR INFORMACIÓN DEL ESTUDIANTE
  Future<void> actualizarEstudiante(int estudianteId, Map<String, dynamic> datos) async {
    try {
      await put('/estudiantes/$estudianteId', datos);
    } catch (e) {
      throw Exception('Error al actualizar el estudiante: $e');
    }
  }
}