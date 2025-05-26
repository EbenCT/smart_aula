// lib/models/participacion.dart
import 'package:flutter/material.dart';

// Enum mantenido para compatibilidad, pero ahora solo usaremos 'comentario' por defecto
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
  final int valoracion; // Ahora 0-100 en lugar de 1-5

  Participacion({
    required this.id,
    required this.estudianteId,
    required this.cursoId,
    required this.fecha,
    this.tipo = TipoParticipacion.comentario, // Por defecto será comentario (participación general)
    this.descripcion,
    this.valoracion = 50, // Valor por defecto 50/100
  });

  factory Participacion.fromJson(Map<String, dynamic> json) {
    return Participacion(
      id: json['id'].toString(),
      estudianteId: json['estudiante_id']?.toString() ?? json['estudianteId']?.toString() ?? '',
      cursoId: json['curso_id']?.toString() ?? json['cursoId']?.toString() ?? '',
      fecha: DateTime.parse(json['fecha']),
      tipo: TipoParticipacion.values.firstWhere(
          (e) => e.toString().split('.').last == (json['tipo'] ?? 'comentario'),
          orElse: () => TipoParticipacion.comentario),
      descripcion: json['descripcion'] ?? 'Participación',
      valoracion: (json['valor'] is double) 
          ? (json['valor'] as double).toInt() 
          : (json['valor'] ?? json['valoracion'] ?? 50) as int,
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

  // Para envío al backend
  Map<String, dynamic> toBackendJson() {
    return {
      'id': int.tryParse(estudianteId) ?? 0,
      'valor': valoracion,
      'descripcion': descripcion ?? 'Participación',
    };
  }

  // Constructor simplificado para participaciones nuevas
  factory Participacion.nueva({
    required String estudianteId,
    required String cursoId,
    required String descripcion,
    required int valoracion,
  }) {
    return Participacion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      estudianteId: estudianteId,
      cursoId: cursoId,
      fecha: DateTime.now(),
      tipo: TipoParticipacion.comentario,
      descripcion: descripcion.isEmpty ? 'Participación' : descripcion,
      valoracion: valoracion,
    );
  }

  // Getter para compatibilidad con código anterior
  Color getColorIndicador() {
    if (valoracion >= 85) {
      return Colors.green;
    } else if (valoracion >= 70) {
      return Colors.lightGreen;
    } else if (valoracion >= 50) {
      return Colors.amber;
    } else if (valoracion >= 25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Getter para texto descriptivo del puntaje
  String get textoValoracion {
    if (valoracion >= 85) {
      return 'Excelente';
    } else if (valoracion >= 70) {
      return 'Muy Bueno';
    } else if (valoracion >= 50) {
      return 'Bueno';
    } else if (valoracion >= 25) {
      return 'Regular';
    } else {
      return 'Básico';
    }
  }
}