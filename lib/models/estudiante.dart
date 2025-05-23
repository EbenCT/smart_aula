class Estudiante {
  final int id;
  final String nombre;
  final String apellido;
  final DateTime fechaNacimiento;
  final String genero;
  final String? urlImagen;
  final String nombreTutor;
  final String telefonoTutor;
  final String direccionCasa;
  
  // Campos adicionales para compatibilidad con la app (pueden ser calculados o venir de otros endpoints)
  final Map<String, double> notas;
  final double porcentajeAsistencia;
  final int participaciones;
  final Map<String, dynamic>? prediccion;

  Estudiante({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.genero,
    this.urlImagen,
    required this.nombreTutor,
    required this.telefonoTutor,
    required this.direccionCasa,
    this.notas = const {},
    this.porcentajeAsistencia = 0.0,
    this.participaciones = 0,
    this.prediccion,
  });

  String get nombreCompleto => '$nombre $apellido';
  
  // Getter para código de estudiante (generado a partir del ID)
  String get codigo => 'EST${id.toString().padLeft(3, '0')}';
  
  // Getter para email (generado a partir del nombre)
  String get email => '${nombre.toLowerCase()}.${apellido.toLowerCase()}@estudiante.edu'.replaceAll(' ', '');

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento']),
      genero: json['genero'],
      urlImagen: json['url_imagen'],
      nombreTutor: json['nombre_tutor'],
      telefonoTutor: json['telefono_tutor'],
      direccionCasa: json['direccion_casa'],
      // Campos adicionales que pueden venir de otros endpoints o ser calculados
      notas: Map<String, double>.from(json['notas'] ?? {}),
      porcentajeAsistencia: json['porcentaje_asistencia']?.toDouble() ?? 0.0,
      participaciones: json['participaciones'] ?? 0,
      prediccion: json['prediccion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T')[0], // Solo fecha
      'genero': genero,
      'url_imagen': urlImagen,
      'nombre_tutor': nombreTutor,
      'telefono_tutor': telefonoTutor,
      'direccion_casa': direccionCasa,
      'notas': notas,
      'porcentaje_asistencia': porcentajeAsistencia,
      'participaciones': participaciones,
      'prediccion': prediccion,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Estudiante && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}