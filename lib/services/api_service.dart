// lib/services/api_service.dart
import './auth_service.dart';
import './curso_api_service.dart';
import './estudiante_api_service.dart';
import './evaluacion_api_service.dart';
import './prediccion_api_service.dart';
import './resumen_api_service.dart';
import '../models/curso.dart';
import '../models/materia.dart';
import '../models/estudiante.dart';
import '../models/asistencia.dart';
import '../models/participacion.dart';

class ApiService {
  final AuthService _authService;
  
  late final CursoApiService cursos;
  late final EstudianteApiService estudiantes;
  late final EvaluacionApiService evaluaciones;
  late final PrediccionApiService predicciones;
  late final ResumenApiService resumen;
  
  ApiService(this._authService) {
    cursos = CursoApiService(_authService);
    estudiantes = EstudianteApiService(_authService);
    evaluaciones = EvaluacionApiService(_authService);
    predicciones = PrediccionApiService(_authService);
    resumen = ResumenApiService(_authService);
  }

  // RESUMEN DE MATERIA
  Future<Map<String, dynamic>> getResumenMateriaCompleto(int cursoId, int materiaId) => 
      resumen.getResumenMateriaCompleto(cursoId, materiaId);
  
  Future<Map<String, dynamic>> getResumenMateriaPorPeriodo(int cursoId, int materiaId, int periodoId) => 
      resumen.getResumenMateriaPorPeriodo(cursoId, materiaId, periodoId);

  // Métodos de conveniencia para mantener compatibilidad con código existente
  
  // CURSOS
  Future<List<Curso>> getCursosDocente() => cursos.getCursosDocente();
  Future<List<Materia>> getMateriasDocente(int cursoId) => cursos.getMateriasDocente(cursoId);
  
  // ESTUDIANTES
  Future<List<Estudiante>> getEstudiantesPorMateria(int cursoId, int materiaId) => 
      estudiantes.getEstudiantesPorMateria(cursoId, materiaId);
  
  // ASISTENCIAS - Métodos actualizados
  Future<Map<String, dynamic>> getAsistenciasMasivas({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
  }) => evaluaciones.getAsistenciasMasivas(
    cursoId: cursoId,
    materiaId: materiaId,
    fecha: fecha,
  );

  Future<List<Asistencia>> getAsistenciaPorCursoYFecha(
    String cursoId, 
    DateTime fecha
  ) async {
    // Convertir cursoId de String a int para el nuevo método
    final cursoIdInt = int.tryParse(cursoId) ?? 0;
    return evaluaciones.getAsistenciasPorCursoYFecha(cursoIdInt, cursoIdInt, fecha);
  }

  // PARTICIPACIONES - Métodos nuevos
  Future<Map<String, dynamic>> getParticipacionesMasivas({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
  }) => evaluaciones.getParticipacionesMasivas(
    cursoId: cursoId,
    materiaId: materiaId,
    fecha: fecha,
  );

  Future<List<Participacion>> getParticipacionesPorEstudiante(
    int estudianteId,
    int cursoId,
    int materiaId,
    {DateTime? fechaInicio, DateTime? fechaFin}
  ) => evaluaciones.getParticipacionesPorEstudiante(
    estudianteId,
    cursoId,
    materiaId,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
  );
  
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

  // Método para mapear estado desde el backend
  EstadoAsistencia mapearEstadoDesdeBackend(dynamic valor) =>
      evaluaciones.mapearEstadoDesdeBackend(valor);

  // Método para mapear estado a valor numérico
  int mapearEstadoAValor(EstadoAsistencia estado) =>
      evaluaciones.mapearEstadoAValor(estado);

  // Métodos legacy para compatibilidad
  Future<void> registrarAsistencia(Asistencia asistencia) async {
    // Para compatibilidad - no hace nada por ahora
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> registrarParticipacion(Participacion participacion) async {
    // Para compatibilidad - no hace nada por ahora
    await Future.delayed(const Duration(milliseconds: 100));
  }
}