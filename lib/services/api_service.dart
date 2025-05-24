// lib/services/api_service.dart
import './auth_service.dart';
import './curso_api_service.dart';
import './estudiante_api_service.dart';
import './evaluacion_api_service.dart';
import './prediccion_api_service.dart';
import '../models/curso.dart';
import '../models/materia.dart';
import '../models/estudiante.dart';
import '../models/asistencia.dart';

class ApiService {
  final AuthService _authService;
  
  late final CursoApiService cursos;
  late final EstudianteApiService estudiantes;
  late final EvaluacionApiService evaluaciones;
  late final PrediccionApiService predicciones;
  
  ApiService(this._authService) {
    cursos = CursoApiService(_authService);
    estudiantes = EstudianteApiService(_authService);
    evaluaciones = EvaluacionApiService(_authService);
    predicciones = PrediccionApiService(_authService);
  }

  // Métodos de conveniencia para mantener compatibilidad con código existente
  
  // CURSOS
  Future<List<Curso>> getCursosDocente() => cursos.getCursosDocente();
  Future<List<Materia>> getMateriasDocente(int cursoId) => cursos.getMateriasDocente(cursoId);
  
  // ESTUDIANTES
  Future<List<Estudiante>> getEstudiantesPorMateria(int cursoId, int materiaId) => 
      estudiantes.getEstudiantesPorMateria(cursoId, materiaId);
  
  // ASISTENCIAS - Método que faltaba
  Future<List<Asistencia>> getAsistenciaPorCursoYFecha(
    String cursoId, 
    DateTime fecha
  ) async {
    // Convertir cursoId de String a int para el nuevo método
    final cursoIdInt = int.tryParse(cursoId) ?? 0;
    return evaluaciones.getAsistenciasPorCursoYFecha(cursoIdInt, cursoIdInt, fecha);
  }
  
  // EVALUACIONES
  Future<void> enviarAsistencias({
    required int docenteId,
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
    required List<Map<String, dynamic>> asistencias,
  }) => evaluaciones.enviarAsistencias(
    docenteId: docenteId,
    cursoId: cursoId,
    materiaId: materiaId,
    fecha: fecha,
    asistencias: asistencias,
  );

  Future<void> enviarParticipaciones({
    required int docenteId,
    required int cursoId,
    required int materiaId,
    required int periodoId,
    required DateTime fecha,
    required List<Map<String, dynamic>> participaciones,
  }) => evaluaciones.enviarParticipaciones(
    docenteId: docenteId,
    cursoId: cursoId,
    materiaId: materiaId,
    periodoId: periodoId,
    fecha: fecha,
    participaciones: participaciones,
  );

  // Método para mapear estados de asistencia
  String mapearEstadoAsistencia(dynamic estado) => 
      evaluaciones.mapearEstadoAsistencia(estado);

  // Métodos legacy para compatibilidad
  Future<void> registrarAsistencia(Asistencia asistencia) async {
    // Para compatibilidad - no hace nada por ahora
    await Future.delayed(const Duration(milliseconds: 100));
  }
}