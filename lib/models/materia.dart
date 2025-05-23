class Materia {
  final int id;
  final String nombre;
  final String descripcion;

  Materia({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Materia && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}