// lib/services/curso_api_service.dart
import '../models/curso.dart';
import '../models/materia.dart';
import './base_api_service.dart';
import './auth_service.dart';

class CursoApiService extends BaseApiService {
  final AuthService _authService;
  
  CursoApiService(this._authService) : super(_authService);

  // CURSOS DEL DOCENTE
  Future<List<Curso>> getCursosDocente() async {
    try {
      final userId = _authService.usuario?.id ?? _authService.userId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await get('/docentes/cursos-docente/$userId');
      
      if (response is List) {
        return response.map((json) => Curso.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener los cursos: $e');
    }
  }

  // MATERIAS DEL DOCENTE POR CURSO
  Future<List<Materia>> getMateriasDocente(int cursoId) async {
    try {
      final userId = _authService.usuario?.id ?? _authService.userId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await get('/docentes/$userId/curso/$cursoId/materias');
      
      if (response is List) {
        return response.map((json) => Materia.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener las materias: $e');
    }
  }
}