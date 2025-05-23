// lib/widgets/asistencia_item.dart
import 'package:flutter/material.dart';
import '../models/asistencia.dart';
import '../models/estudiante.dart';
import 'student_list_item_widget.dart';
import 'attendance_selector_widget.dart';

class AsistenciaItem extends StatelessWidget {
  final Estudiante estudiante;
  final Asistencia asistencia;
  final Function(EstadoAsistencia) onAsistenciaChanged;

  const AsistenciaItem({
    Key? key,
    required this.estudiante,
    required this.asistencia,
    required this.onAsistenciaChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StudentListItemWidget(
      estudiante: estudiante,
      trailingWidget: _buildObservationIndicator(context),
      bottomWidget: AttendanceSelectorWidget(
        currentState: asistencia.estado,
        onStateChanged: onAsistenciaChanged,
        isCompact: true,
      ),
    );
  }

  Widget? _buildObservationIndicator(BuildContext context) {
    if (asistencia.observacion == null || asistencia.observacion!.isEmpty) {
      return null;
    }

    return GestureDetector(
      onTap: () => _mostrarObservacion(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getColorForEstado(asistencia.estado).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.info_outline,
          size: 16,
          color: _getColorForEstado(asistencia.estado),
        ),
      ),
    );
  }

  void _mostrarObservacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Observación - ${_getTituloEstado(asistencia.estado)}',
          style: const TextStyle(fontSize: 18),
        ),
        content: Text(
          asistencia.observacion ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  Color _getColorForEstado(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return Colors.green;
      case EstadoAsistencia.tardanza:
        return Colors.amber;
      case EstadoAsistencia.ausente:
        return Colors.red;
      case EstadoAsistencia.justificado:
        return Colors.blue;
    }
  }

  String _getTituloEstado(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'Presente';
      case EstadoAsistencia.tardanza:
        return 'Tardanza';
      case EstadoAsistencia.ausente:
        return 'Ausente';
      case EstadoAsistencia.justificado:
        return 'Justificado';
    }
  }
}