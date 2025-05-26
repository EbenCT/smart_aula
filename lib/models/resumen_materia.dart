// lib/models/resumen_materia.dart

class ResumenPorPeriodo {
  final int periodoId;
  final double promedioNotas;
  final double promedioAsistencia;
  final double promedioParticipacion;

  ResumenPorPeriodo({
    required this.periodoId,
    required this.promedioNotas,
    required this.promedioAsistencia,
    required this.promedioParticipacion,
  });

  factory ResumenPorPeriodo.fromJson(Map<String, dynamic> json) {
    return ResumenPorPeriodo(
      periodoId: json['periodo_id'] ?? 1,
      promedioNotas: (json['promedio_notas'] ?? 0).toDouble(),
      promedioAsistencia: (json['promedio_asistencia'] ?? 0).toDouble(),
      promedioParticipacion: (json['promedio_participacion'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodo_id': periodoId,
      'promedio_notas': promedioNotas,
      'promedio_asistencia': promedioAsistencia,
      'promedio_participacion': promedioParticipacion,
    };
  }
}

class PromedioGeneral {
  final double notas;
  final double asistencia;
  final double participacion;

  PromedioGeneral({
    required this.notas,
    required this.asistencia,
    required this.participacion,
  });

  factory PromedioGeneral.fromJson(Map<String, dynamic> json) {
    return PromedioGeneral(
      notas: (json['notas'] ?? 0).toDouble(),
      asistencia: (json['asistencia'] ?? 0).toDouble(),
      participacion: (json['participacion'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notas': notas,
      'asistencia': asistencia,
      'participacion': participacion,
    };
  }
}

class ResumenMateriaCompleto {
  final int totalEstudiantes;
  final List<ResumenPorPeriodo> resumenPorPeriodo;
  final PromedioGeneral promedioGeneral;

  ResumenMateriaCompleto({
    required this.totalEstudiantes,
    required this.resumenPorPeriodo,
    required this.promedioGeneral,
  });

  factory ResumenMateriaCompleto.fromJson(Map<String, dynamic> json) {
    return ResumenMateriaCompleto(
      totalEstudiantes: json['total_estudiantes'] ?? 0,
      resumenPorPeriodo: (json['resumen_por_periodo'] as List<dynamic>?)
          ?.map((item) => ResumenPorPeriodo.fromJson(item))
          .toList() ?? [],
      promedioGeneral: PromedioGeneral.fromJson(json['promedio_general'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_estudiantes': totalEstudiantes,
      'resumen_por_periodo': resumenPorPeriodo.map((item) => item.toJson()).toList(),
      'promedio_general': promedioGeneral.toJson(),
    };
  }

  // Obtener el resumen del primer periodo (o periodo actual)
  ResumenPorPeriodo? get resumenPeriodoActual {
    return resumenPorPeriodo.isNotEmpty ? resumenPorPeriodo.first : null;
  }

  // Verificar si hay datos de notas disponibles
  bool get tieneNotas {
    return promedioGeneral.notas > 0 || 
           resumenPorPeriodo.any((periodo) => periodo.promedioNotas > 0);
  }

  // Verificar si hay datos de asistencia disponibles
  bool get tieneAsistencia {
    return promedioGeneral.asistencia > 0 || 
           resumenPorPeriodo.any((periodo) => periodo.promedioAsistencia > 0);
  }

  // Verificar si hay datos de participación disponibles
  bool get tieneParticipacion {
    return promedioGeneral.participacion > 0 || 
           resumenPorPeriodo.any((periodo) => periodo.promedioParticipacion > 0);
  }
}