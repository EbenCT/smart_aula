// lib/widgets/attendance_selector_widget.dart
import 'package:flutter/material.dart';
import '../models/asistencia.dart';

class AttendanceSelectorWidget extends StatelessWidget {
  final EstadoAsistencia currentState;
  final Function(EstadoAsistencia) onStateChanged;
  final bool isCompact;

  const AttendanceSelectorWidget({
    Key? key,
    required this.currentState,
    required this.onStateChanged,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600 || isCompact;

    if (isSmallScreen) {
      return _buildCompactSelector(context, isDarkMode);
    } else {
      return _buildSegmentedSelector(context, isDarkMode);
    }
  }

  Widget _buildCompactSelector(BuildContext context, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: EstadoAsistencia.values.map((estado) {
        return _buildCompactButton(context, estado, isDarkMode);
      }).toList(),
    );
  }

  Widget _buildCompactButton(BuildContext context, EstadoAsistencia estado, bool isDarkMode) {
    final bool isSelected = currentState == estado;
    final color = _getColorForEstado(estado);
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: () => _handleStateChange(context, estado),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? color.withOpacity(isDarkMode ? 0.3 : 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? color 
                    : Theme.of(context).dividerColor.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForEstado(estado),
                  color: isSelected 
                      ? color 
                      : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  _getShortTextForEstado(estado),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? color 
                        : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedSelector(BuildContext context, bool isDarkMode) {
    return SegmentedButton<EstadoAsistencia>(
      segments: EstadoAsistencia.values.map((estado) {
        return ButtonSegment<EstadoAsistencia>(
          value: estado,
          icon: Icon(_getIconForEstado(estado)),
          label: Text(_getTextForEstado(estado)),
        );
      }).toList(),
      selected: {currentState},
      onSelectionChanged: (Set<EstadoAsistencia> newSelection) {
        if (newSelection.isNotEmpty) {
          final nuevoEstado = newSelection.first;
          _handleStateChange(context, nuevoEstado);
        }
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              final color = _getColorForEstado(currentState);
              return color.withOpacity(isDarkMode ? 0.3 : 0.1);
            }
            return Colors.transparent;
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return _getColorForEstado(currentState);
            }
            return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
          },
        ),
        side: MaterialStateProperty.resolveWith<BorderSide>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return BorderSide(
                color: _getColorForEstado(currentState),
                width: 1.5,
              );
            }
            return BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 1,
            );
          },
        ),
      ),
    );
  }

  void _handleStateChange(BuildContext context, EstadoAsistencia estado) {
    if (estado == EstadoAsistencia.tardanza || estado == EstadoAsistencia.justificado) {
      _mostrarDialogoObservacion(context, estado);
    } else {
      onStateChanged(estado);
    }
  }

  void _mostrarDialogoObservacion(BuildContext context, EstadoAsistencia estado) {
    final TextEditingController observacionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          estado == EstadoAsistencia.tardanza ? 'Registrar Tardanza' : 'Registrar Justificación',
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              estado == EstadoAsistencia.tardanza 
                  ? 'Ingrese una observación sobre la tardanza:'
                  : 'Ingrese el motivo de la justificación:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: observacionController,
              decoration: InputDecoration(
                hintText: estado == EstadoAsistencia.tardanza 
                    ? 'Ej: Llegó 15 minutos tarde'
                    : 'Ej: Certificado médico',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              onStateChanged(estado);
              Navigator.of(ctx).pop();
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForEstado(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return Icons.check_circle_outline;
      case EstadoAsistencia.tardanza:
        return Icons.watch_later_outlined;
      case EstadoAsistencia.ausente:
        return Icons.cancel_outlined;
      case EstadoAsistencia.justificado:
        return Icons.note_alt_outlined;
    }
  }

  String _getTextForEstado(EstadoAsistencia estado) {
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

  String _getShortTextForEstado(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'Presente';
      case EstadoAsistencia.tardanza:
        return 'Tarde';
      case EstadoAsistencia.ausente:
        return 'Ausente';
      case EstadoAsistencia.justificado:
        return 'Justif.';
    }
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
}