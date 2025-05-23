class Curso {
  final int id;
  final String nombre;
  final String nivel;
  final String paralelo;
  final String turno;

  Curso({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.paralelo,
    required this.turno,
  });

  // Getter para mostrar información completa del curso
  String get nombreCompleto => '$nombre - $nivel $paralelo ($turno)';
  
  // Getter para mostrar código del curso
  String get codigo => '${nivel.substring(0, 1).toUpperCase()}${paralelo}';

  factory Curso.fromJson(Map<String, dynamic> json) {
    return Curso(
      id: json['id'],
      nombre: json['nombre'],
      nivel: json['nivel'],
      paralelo: json['paralelo'],
      turno: json['turno'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nivel': nivel,
      'paralelo': paralelo,
      'turno': turno,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Curso && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}