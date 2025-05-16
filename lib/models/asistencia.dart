enum EstadoAsistencia { presente, ausente, tardanza, justificado }

class Asistencia {
  final String id;
  final String estudianteId;
  final String cursoId;
  final DateTime fecha;
  final EstadoAsistencia estado;
  final String? observacion;

  Asistencia({
    required this.id,
    required this.estudianteId,
    required this.cursoId,
    required this.fecha,
    required this.estado,
    this.observacion,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'],
      estudianteId: json['estudianteId'],
      cursoId: json['cursoId'],
      fecha: DateTime.parse(json['fecha']),
      estado: EstadoAsistencia.values.firstWhere(
          (e) => e.toString().split('.').last == json['estado'],
          orElse: () => EstadoAsistencia.ausente),
      observacion: json['observacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estudianteId': estudianteId,
      'cursoId': cursoId,
      'fecha': fecha.toIso8601String(),
      'estado': estado.toString().split('.').last,
      'observacion': observacion,
    };
  }
}