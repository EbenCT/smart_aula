import 'package:flutter/material.dart';

enum NivelRendimiento { bajo, medio, alto }

class Prediccion {
  final String id;
  final String estudianteId;
  final String cursoId;
  final DateTime fechaPrediccion;
  final double valorNumerico;
  final NivelRendimiento nivel;
  final List<String> factoresInfluyentes;

  Prediccion({
    required this.id,
    required this.estudianteId,
    required this.cursoId,
    required this.fechaPrediccion,
    required this.valorNumerico,
    required this.nivel,
    this.factoresInfluyentes = const [],
  });

  factory Prediccion.fromJson(Map<String, dynamic> json) {
    return Prediccion(
      id: json['id'],
      estudianteId: json['estudianteId'],
      cursoId: json['cursoId'],
      fechaPrediccion: DateTime.parse(json['fechaPrediccion']),
      valorNumerico: json['valorNumerico']?.toDouble() ?? 0.0,
      nivel: NivelRendimiento.values.firstWhere(
          (e) => e.toString().split('.').last == json['nivel'],
          orElse: () => NivelRendimiento.medio),
      factoresInfluyentes: List<String>.from(json['factoresInfluyentes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estudianteId': estudianteId,
      'cursoId': cursoId,
      'fechaPrediccion': fechaPrediccion.toIso8601String(),
      'valorNumerico': valorNumerico,
      'nivel': nivel.toString().split('.').last,
      'factoresInfluyentes': factoresInfluyentes,
    };
  }

  Color getColorIndicador() {
    switch (nivel) {
      case NivelRendimiento.bajo:
        return Colors.red;
      case NivelRendimiento.medio:
        return Colors.amber;
      case NivelRendimiento.alto:
        return Colors.green;
    }
  }
}