import 'package:flutter/material.dart';
import '../../models/asistencia.dart';
import '../../models/estudiante.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                estudiante.nombre.substring(0, 1) +
                    estudiante.apellido.substring(0, 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudiante.nombreCompleto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(estudiante.codigo),
                ],
              ),
            ),
            _buildAsistenciaToggle(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciaToggle(BuildContext context) {
    return SegmentedButton<EstadoAsistencia>(
      segments: const [
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.presente,
          icon: Icon(Icons.check_circle),
          label: Text('P'),
        ),
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.tardanza,
          icon: Icon(Icons.watch_later),
          label: Text('T'),
        ),
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.ausente,
          icon: Icon(Icons.cancel),
          label: Text('A'),
        ),
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.justificado,
          icon: Icon(Icons.note),
          label: Text('J'),
        ),
      ],
      selected: {asistencia.estado},
      onSelectionChanged: (Set<EstadoAsistencia> newSelection) {
        if (newSelection.isNotEmpty) {
          onAsistenciaChanged(newSelection.first);
        }
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              switch (asistencia.estado) {
                case EstadoAsistencia.presente:
                  return Colors.green.shade100;
                case EstadoAsistencia.tardanza:
                  return Colors.amber.shade100;
                case EstadoAsistencia.ausente:
                  return Colors.red.shade100;
                case EstadoAsistencia.justificado:
                  return Colors.blue.shade100;
              }
            }
            return Colors.transparent;
          },
        ),
      ),
    );
  }
}