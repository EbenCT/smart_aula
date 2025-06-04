// lib/models/prediccion_completa.dart
import 'package:flutter/material.dart';

class PrediccionCompleta {
  final int periodoId;
  final String periodoNombre;
  final int estudianteId;
  final int materiaId;
  final double promedioNotas;
  final double porcentajeAsistencia;
  final double promedioParticipacion;
  final double resultadoNumerico;
  final String clasificacion;
  final DateTime fechaGenerada;

  PrediccionCompleta({
    required this.periodoId,
    required this.periodoNombre,
    required this.estudianteId,
    required this.materiaId,
    required this.promedioNotas,
    required this.porcentajeAsistencia,
    required this.promedioParticipacion,
    required this.resultadoNumerico,
    required this.clasificacion,
    required this.fechaGenerada,
  });

  factory PrediccionCompleta.fromJson(Map<String, dynamic> json) {
    return PrediccionCompleta(
      periodoId: json['periodo_id'] ?? 0,
      periodoNombre: json['periodo_nombre'] ?? '',
      estudianteId: json['estudiante_id'] ?? 0,
      materiaId: json['materia_id'] ?? 0,
      promedioNotas: (json['promedio_notas'] ?? 0).toDouble(),
      porcentajeAsistencia: (json['porcentaje_asistencia'] ?? 0).toDouble(),
      promedioParticipacion: (json['promedio_participacion'] ?? 0).toDouble(),
      resultadoNumerico: (json['resultado_numerico'] ?? 0).toDouble(),
      clasificacion: json['clasificacion'] ?? '',
      fechaGenerada: DateTime.parse(json['fecha_generada']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodo_id': periodoId,
      'periodo_nombre': periodoNombre,
      'estudiante_id': estudianteId,
      'materia_id': materiaId,
      'promedio_notas': promedioNotas,
      'porcentaje_asistencia': porcentajeAsistencia,
      'promedio_participacion': promedioParticipacion,
      'resultado_numerico': resultadoNumerico,
      'clasificacion': clasificacion,
      'fecha_generada': fechaGenerada.toIso8601String(),
    };
  }

  // Getter para obtener color según la clasificación
  Color get colorClasificacion {
    switch (clasificacion.toLowerCase()) {
      case 'alto':
        return Colors.green;
      case 'medio':
        return Colors.amber;
      case 'bajo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Getter para obtener ícono según la clasificación
  IconData get iconoClasificacion {
    switch (clasificacion.toLowerCase()) {
      case 'alto':
        return Icons.trending_up;
      case 'medio':
        return Icons.trending_flat;
      case 'bajo':
        return Icons.trending_down;
      default:
        return Icons.help_outline;
    }
  }

  // Getter para obtener descripción de la predicción
  String get descripcionPrediccion {
    switch (clasificacion.toLowerCase()) {
      case 'alto':
        return 'El estudiante muestra un rendimiento excelente y se espera que continúe así.';
      case 'medio':
        return 'El estudiante mantiene un rendimiento estable con oportunidades de mejora.';
      case 'bajo':
        return 'El estudiante necesita apoyo adicional para mejorar su rendimiento.';
      default:
        return 'No se pudo determinar una clasificación clara.';
    }
  }

  // Getter para obtener recomendaciones basadas en las métricas
  List<String> get recomendaciones {
    List<String> recomendaciones = [];

    if (promedioNotas < 60) {
      recomendaciones.add('Enfocarse en mejorar las calificaciones mediante tutoría adicional');
    }

    if (porcentajeAsistencia < 80) {
      recomendaciones.add('Mejorar la asistencia regular a clases');
    }

    if (promedioParticipacion < 50) {
      recomendaciones.add('Fomentar la participación activa en clase');
    }

    if (resultadoNumerico < 65) {
      recomendaciones.add('Implementar un plan de seguimiento personalizado');
    }

    if (recomendaciones.isEmpty) {
      recomendaciones.add('Mantener el buen rendimiento actual');
    }

    return recomendaciones;
  }

  // Getter para obtener el área de mayor fortaleza
  String get areaFortaleza {
    final Map<String, double> metricas = {
      'Notas': promedioNotas,
      'Asistencia': porcentajeAsistencia,
      'Participación': promedioParticipacion,
    };

    final entradaMaxima = metricas.entries.reduce(
      (a, b) => a.value > b.value ? a : b
    );

    return entradaMaxima.key;
  }

  // Getter para obtener el área que necesita más atención
  String get areaMejora {
    final Map<String, double> metricas = {
      'Notas': promedioNotas,
      'Asistencia': porcentajeAsistencia,
      'Participación': promedioParticipacion,
    };

    final entradaMinima = metricas.entries.reduce(
      (a, b) => a.value < b.value ? a : b
    );

    return entradaMinima.key;
  }

  @override
  String toString() {
    return 'PrediccionCompleta(periodo: $periodoNombre, estudiante: $estudianteId, resultado: $resultadoNumerico, clasificacion: $clasificacion)';
  }
}