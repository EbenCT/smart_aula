class Estudiante {
  final String id;
  final String nombre;
  final String apellido;
  final String codigo;
  final String email;
  final Map<String, double> notas;
  final double porcentajeAsistencia;
  final int participaciones;
  final Map<String, dynamic>? prediccion;

  Estudiante({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.codigo,
    required this.email,
    this.notas = const {},
    this.porcentajeAsistencia = 0.0,
    this.participaciones = 0,
    this.prediccion,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      codigo: json['codigo'],
      email: json['email'],
      notas: Map<String, double>.from(json['notas'] ?? {}),
      porcentajeAsistencia: json['porcentajeAsistencia']?.toDouble() ?? 0.0,
      participaciones: json['participaciones'] ?? 0,
      prediccion: json['prediccion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'codigo': codigo,
      'email': email,
      'notas': notas,
      'porcentajeAsistencia': porcentajeAsistencia,
      'participaciones': participaciones,
      'prediccion': prediccion,
    };
  }
}