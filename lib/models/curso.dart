class Curso {
  final String id;
  final String nombre;
  final String codigo;
  final String periodoId;

  Curso({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.periodoId,
  });

  factory Curso.fromJson(Map<String, dynamic> json) {
    return Curso(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      periodoId: json['periodoId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'periodoId': periodoId,
    };
  }
}