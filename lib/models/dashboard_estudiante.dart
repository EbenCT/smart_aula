// lib/models/dashboard_estudiante.dart
class DashboardEstudiante {
  final Map<String, dynamic> estudiante;
  final Map<String, dynamic> curso;
  final Map<String, dynamic> gestion;
  final Map<String, dynamic> estadisticas;
  final List<dynamic> materias;

  DashboardEstudiante({
    required this.estudiante,
    required this.curso, 
    required this.gestion,
    required this.estadisticas,
    required this.materias,
  });

  factory DashboardEstudiante.fromJson(Map<String, dynamic> json) {
    return DashboardEstudiante(
      estudiante: json['estudiante'] ?? {},
      curso: json['curso'] ?? {},
      gestion: json['gestion'] ?? {},
      estadisticas: json['estadisticas'] ?? {},
      materias: json['materias'] ?? [],
    );
  }

  String get nombreEstudiante => '${estudiante['nombre']} ${estudiante['apellido']}';
  String get nombreCurso => '${curso['nombre']} - ${curso['turno']}';
  int get totalMaterias => estadisticas['total_materias'] ?? 0;
  int get materiasConDocente => estadisticas['materias_con_docente'] ?? 0;
  int get totalDocentes => estadisticas['total_docentes'] ?? 0;
  double get porcentajeCompleto => totalMaterias > 0 ? (materiasConDocente / totalMaterias * 100) : 0.0;
}