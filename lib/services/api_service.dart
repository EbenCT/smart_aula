// lib/services/api_service.dart
import './auth_service.dart';
import './curso_api_service.dart';
import './estudiante_api_service.dart';
import './evaluacion_api_service.dart';
import './prediccion_api_service.dart';
import './resumen_api_service.dart';
import './resumen_estudiante_api_service.dart';
import './prediccion_completa_api_service.dart';
import '../models/curso.dart';
import '../models/materia.dart';
import '../models/estudiante.dart';
import '../models/asistencia.dart';
import '../models/participacion.dart';
import '../models/prediccion_completa.dart';
import './padre_api_service.dart';
import 'notification_api_service.dart'; 

class ApiService {
  final AuthService _authService;
  
  late final CursoApiService cursos;
  late final EstudianteApiService estudiantes;
  late final EvaluacionApiService evaluaciones;
  late final PrediccionApiService predicciones;
  late final ResumenApiService resumen;
  late final ResumenEstudianteApiService resumenEstudiante;
  late final PrediccionCompletaApiService prediccionesCompletas;
  late final PadreApiService padres;
  late final NotificationApiService notificaciones;
  
  ApiService(this._authService) {
    cursos = CursoApiService(_authService);
    estudiantes = EstudianteApiService(_authService);
    evaluaciones = EvaluacionApiService(_authService);
    predicciones = PrediccionApiService(_authService);
    resumen = ResumenApiService(_authService);
    resumenEstudiante = ResumenEstudianteApiService(_authService);
    prediccionesCompletas = PrediccionCompletaApiService(_authService);
    padres = PadreApiService(_authService);
    notificaciones = NotificationApiService(_authService);
  }
    // SERVICIOS PARA PADRES
  // Obtener lista de hijos del padre autenticado
  Future<List<Estudiante>> getMisHijos() => padres.getMisHijos();
  
  // Refrescar lista de hijos
  Future<List<Estudiante>> refrescarHijos() => padres.refrescarHijos();

  //SERVICIOS DE NOTIFICACIONES
  // Obtener mis notificaciones
  Future<List<Map<String, dynamic>>> obtenerMisNotificaciones({
    int limit = 50,
    bool soloNoLeidas = false,
  }) => notificaciones.obtenerMisNotificaciones(
    limit: limit, 
    soloNoLeidas: soloNoLeidas
  );

  // Marcar notificación como leída
  Future<Map<String, dynamic>> marcarNotificacionComoLeida(int notificationId) =>
      notificaciones.marcarNotificacionComoLeida(notificationId);

  // Contar notificaciones no leídas
  Future<int> contarNotificacionesNoLeidas() => 
      notificaciones.contarNotificacionesNoLeidas();

  // PREDICCIONES COMPLETAS
  Future<List<PrediccionCompleta>> getPrediccionesCompletas({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) => prediccionesCompletas.getPrediccionesCompletas(
    estudianteId: estudianteId,
    materiaId: materiaId,
    gestionId: gestionId,
  );

  Future<PrediccionCompleta?> getPrediccionPorPeriodo({
    required int estudianteId,
    required int materiaId,
    required int periodoId,
    int gestionId = 2,
  }) => prediccionesCompletas.getPrediccionPorPeriodo(
    estudianteId: estudianteId,
    materiaId: materiaId,
    periodoId: periodoId,
    gestionId: gestionId,
  );

  Future<Map<String, dynamic>> getEstadisticasPredicciones({
    required int estudianteId,
    required int materiaId,
    int gestionId = 2,
  }) => prediccionesCompletas.getEstadisticasPredicciones(
    estudianteId: estudianteId,
    materiaId: materiaId,
    gestionId: gestionId,
  );

  // RESUMEN DE MATERIA
  Future<Map<String, dynamic>> getResumenMateriaCompleto(int cursoId, int materiaId) => 
      resumen.getResumenMateriaCompleto(cursoId, materiaId);
  
  Future<Map<String, dynamic>> getResumenMateriaPorPeriodo(int cursoId, int materiaId, int periodoId) => 
      resumen.getResumenMateriaPorPeriodo(cursoId, materiaId, periodoId);

  // RESUMEN POR ESTUDIANTE
  Future<Map<String, dynamic>> getResumenPorEstudiante({
    required int estudianteId,
    required int materiaId,
    int? periodoId,
  }) => resumenEstudiante.getResumenPorEstudiante(
    estudianteId: estudianteId,
    materiaId: materiaId,
    periodoId: periodoId,
  );

  // Métodos de conveniencia para mantener compatibilidad con código existente
  
  // CURSOS
  Future<List<Curso>> getCursosDocente() => cursos.getCursosDocente();
  Future<List<Materia>> getMateriasDocente(int cursoId) => cursos.getMateriasDocente(cursoId);
  
  // ESTUDIANTES
  Future<List<Estudiante>> getEstudiantesPorMateria(int cursoId, int materiaId) => 
      estudiantes.getEstudiantesPorMateria(cursoId, materiaId);
  
  Future<Estudiante> getEstudiantePorId(int estudianteId) => 
      estudiantes.getEstudiantePorId(estudianteId);

  Future<void> actualizarEstudiante(int estudianteId, Map<String, dynamic> datos) => 
      estudiantes.actualizarEstudiante(estudianteId, datos);
  
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

  Future<List<Asistencia>> getAsistenciasPorCursoYFecha(
    int cursoId,
    int materiaId,
    DateTime fecha,
  ) => evaluaciones.getAsistenciasPorCursoYFecha(cursoId, materiaId, fecha);

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

  // PREDICCIONES
  Future<List<Map<String, dynamic>>> getPrediccionesPorCursoYMateria(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      final prediccionesList = await predicciones.getPrediccionesPorCursoYMateria(cursoId, materiaId, periodoId: periodoId);
      return prediccionesList.map((p) => p.toJson()).toList();
    } catch (e) {
      throw Exception('Error al obtener predicciones: $e');
    }
  }

  Future<Map<String, dynamic>?> getPrediccionEstudiante(
    int estudianteId, 
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) async {
    try {
      final prediccion = await predicciones.getPrediccionEstudiante(estudianteId, cursoId, materiaId, periodoId: periodoId);
      return prediccion?.toJson();
    } catch (e) {
      throw Exception('Error al obtener predicción del estudiante: $e');
    }
  }

  Future<void> generarPredicciones(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) => predicciones.generarPredicciones(cursoId, materiaId, periodoId: periodoId);

  Future<Map<String, dynamic>> getEstadisticasDashboard(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) => predicciones.getEstadisticasDashboard(cursoId, materiaId, periodoId: periodoId);

  Future<List<Map<String, dynamic>>> getEstudiantesEnRiesgo(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) => predicciones.getEstudiantesEnRiesgo(cursoId, materiaId, periodoId: periodoId);

  Future<Map<String, int>> getDistribucionRendimiento(
    int cursoId, 
    int materiaId,
    {int? periodoId}
  ) => predicciones.getDistribucionRendimiento(cursoId, materiaId, periodoId: periodoId);

  Future<List<Map<String, dynamic>>> getTendenciasAsistencia(
    int cursoId, 
    int materiaId,
    {int? periodoId, DateTime? fechaInicio, DateTime? fechaFin}
  ) => predicciones.getTendenciasAsistencia(
    cursoId, 
    materiaId, 
    periodoId: periodoId,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
  );

  // Métodos para mapear estados de asistencia
  String mapearEstadoAsistencia(dynamic estado) => 
      evaluaciones.mapearEstadoAsistencia(estado);

  EstadoAsistencia mapearEstadoDesdeBackend(dynamic valor) =>
      evaluaciones.mapearEstadoDesdeBackend(valor);

  int mapearEstadoAValor(EstadoAsistencia estado) =>
      evaluaciones.mapearEstadoAValor(estado);

  // Métodos legacy para compatibilidad (mantienen la interfaz anterior)
  Future<void> registrarAsistencia(Asistencia asistencia) async {
    // Para compatibilidad - no hace nada por ahora
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> registrarParticipacion(Participacion participacion) async {
    // Para compatibilidad - no hace nada por ahora
    await Future.delayed(const Duration(milliseconds: 100));
  }
// DASHBOARD ESTUDIANTE
Future<Map<String, dynamic>> getDashboardEstudiante() => 
    estudiantes.getDashboardEstudiante();

}