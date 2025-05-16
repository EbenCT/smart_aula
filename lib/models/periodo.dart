class Periodo {
  final String id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activo;

  Periodo({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    this.activo = false,
  });

  factory Periodo.fromJson(Map<String, dynamic> json) {
    return Periodo(
      id: json['id'],
      nombre: json['nombre'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      activo: json['activo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'activo': activo,
    };
  }
}