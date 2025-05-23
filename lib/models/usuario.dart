class Usuario {
  final String nombre;
  final String apellido;
  final String telefono;
  final String correo;
  final String genero;
  final bool isDoc;
  final int id;

  Usuario({
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.correo,
    required this.genero,
    required this.isDoc,
    required this.id,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      telefono: json['telefono'] ?? '',
      correo: json['correo'] ?? '',
      genero: json['genero'] ?? '',
      isDoc: json['is_doc'] ?? false,
      id: json['id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'correo': correo,
      'genero': genero,
      'is_doc': isDoc,
      'id': id,
    };
  }
}