enum TipoParticipacion { 
  pregunta, 
  respuesta, 
  comentario, 
  presentacion 
}

class Participacion {
  final String id;
  final String estudianteId;
  final String cursoId;
  final DateTime fecha;
  final TipoParticipacion tipo;
  final String? descripcion;
  final int valoracion; // 1-5

  Participacion({
    required this.id,
    required this.estudianteId,
    required this.cursoId,
    required this.fecha,
    required this.tipo,
    this.descripcion,
    this.valoracion = 3,
  });

  factory Participacion.fromJson(Map<String, dynamic> json) {
    return Participacion(
      id: json['id'],
      estudianteId: json['estudianteId'],
      cursoId: json['cursoId'],
      fecha: DateTime.parse(json['fecha']),
      tipo: TipoParticipacion.values.firstWhere(
          (e) => e.toString().split('.').last == json['tipo'],
          orElse: () => TipoParticipacion.comentario),
      descripcion: json['descripcion'],
      valoracion: json['valoracion'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estudianteId': estudianteId,
      'cursoId': cursoId,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo.toString().split('.').last,
      'descripcion': descripcion,
      'valoracion': valoracion,
    };
  }
}