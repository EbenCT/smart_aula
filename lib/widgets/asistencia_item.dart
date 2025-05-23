// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import '../../models/asistencia.dart';
import '../../models/estudiante.dart';

class AsistenciaItem extends StatefulWidget {
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
  _AsistenciaItemState createState() => _AsistenciaItemState();
}

class _AsistenciaItemState extends State<AsistenciaItem> {
  @override
  Widget build(BuildContext context) {
    // Detectar el ancho de la pantalla para ser responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isSmallScreen
            ? _buildLayoutForSmallScreen(context)
            : _buildLayoutForLargeScreen(context),
      ),
    );
  }

  // Layout para pantallas pequeñas (móviles)
  Widget _buildLayoutForSmallScreen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila superior: Avatar e información del estudiante
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildEstudianteAvatar(),
            const SizedBox(width: 16),
            Expanded(child: _buildEstudianteInfo()),
          ],
        ),
        const SizedBox(height: 16),
        
        // Fila inferior: Botones de asistencia (ocupando todo el ancho)
        _buildAsistenciaButtons(context, true),
      ],
    );
  }

  // Layout para pantallas grandes (tablets, desktop)
  Widget _buildLayoutForLargeScreen(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Primera columna: Avatar del estudiante
        _buildEstudianteAvatar(),
        const SizedBox(width: 16),
        
        // Segunda columna: Información del estudiante y botones de asistencia
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera fila: Nombre y código del estudiante
              _buildEstudianteInfo(),
              const SizedBox(height: 12),
              
              // Segunda fila: Botones de asistencia
              _buildAsistenciaButtons(context, false),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para el avatar del estudiante
  Widget _buildEstudianteAvatar() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        widget.estudiante.nombre.substring(0, 1) + 
        widget.estudiante.apellido.substring(0, 1),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  // Widget para la información del estudiante
  Widget _buildEstudianteInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.estudiante.nombreCompleto,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.asistencia.observacion != null && widget.asistencia.observacion!.isNotEmpty)
              GestureDetector(
                onTap: () => _mostrarObservacion(),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: _getColorForEstado(widget.asistencia.estado),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Código: ${widget.estudiante.codigo}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Widget para los botones de asistencia
  Widget _buildAsistenciaButtons(BuildContext context, bool fullWidth) {
    // Si es pantalla pequeña, usamos botones individuales para mejor experiencia
    if (fullWidth) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAsistenciaButton(
            context, 
            EstadoAsistencia.presente, 
            Icons.check_circle_outline, 
            'Presente', 
            Colors.green
          ),
          _buildAsistenciaButton(
            context, 
            EstadoAsistencia.tardanza, 
            Icons.watch_later_outlined, 
            'Tarde', 
            Colors.amber
          ),
          _buildAsistenciaButton(
            context, 
            EstadoAsistencia.ausente, 
            Icons.cancel_outlined, 
            'Ausente', 
            Colors.red
          ),
          _buildAsistenciaButton(
            context, 
            EstadoAsistencia.justificado, 
            Icons.note_alt_outlined, 
            'Justificado', 
            Colors.blue
          ),
        ],
      );
    }
    
    // Para pantallas grandes usamos SegmentedButton
    return SegmentedButton<EstadoAsistencia>(
      segments: const [
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.presente,
          icon: Icon(Icons.check_circle_outline),
          label: Text('Presente'),
        ),
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.tardanza,
          icon: Icon(Icons.watch_later_outlined),
          label: Text('Tarde'),
        ),
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.ausente,
          icon: Icon(Icons.cancel_outlined),
          label: Text('Ausente'),
        ),
        ButtonSegment<EstadoAsistencia>(
          value: EstadoAsistencia.justificado,
          icon: Icon(Icons.note_alt_outlined),
          label: Text('Justificado'),
        ),
      ],
      selected: {widget.asistencia.estado},
      onSelectionChanged: (Set<EstadoAsistencia> newSelection) {
        if (newSelection.isNotEmpty) {
          final nuevoEstado = newSelection.first;
          
          // Si es tardanza o justificado, mostrar diálogo de observación
          if (nuevoEstado == EstadoAsistencia.tardanza || 
              nuevoEstado == EstadoAsistencia.justificado) {
            _mostrarDialogoObservacion(context, nuevoEstado);
          } else {
            widget.onAsistenciaChanged(nuevoEstado);
          }
        }
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              switch (widget.asistencia.estado) {
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
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              switch (widget.asistencia.estado) {
                case EstadoAsistencia.presente:
                  return Colors.green.shade800;
                case EstadoAsistencia.tardanza:
                  return Colors.amber.shade800;
                case EstadoAsistencia.ausente:
                  return Colors.red.shade800;
                case EstadoAsistencia.justificado:
                  return Colors.blue.shade800;
              }
            }
            return Colors.grey.shade800;
          },
        ),
      ),
    );
  }
  
  // Botón individual para estados de asistencia en pantallas pequeñas
  Widget _buildAsistenciaButton(
    BuildContext context, 
    EstadoAsistencia estado, 
    IconData icon, 
    String label, 
    Color color
  ) {
    final bool isSelected = widget.asistencia.estado == estado;
    
    return InkWell(
      onTap: () {
        if (estado == EstadoAsistencia.tardanza || estado == EstadoAsistencia.justificado) {
          _mostrarDialogoObservacion(context, estado);
        } else {
          widget.onAsistenciaChanged(estado);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Método para mostrar diálogo de observación
  void _mostrarDialogoObservacion(BuildContext context, EstadoAsistencia estado) {
    final TextEditingController observacionController = TextEditingController();
    
    // Si ya hay una observación, la mostramos
    if (widget.asistencia.observacion != null && widget.asistencia.observacion!.isNotEmpty) {
      observacionController.text = widget.asistencia.observacion!;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
              // Actualizar asistencia con la observación
              final nuevaAsistencia = Asistencia(
                id: widget.asistencia.id,
                estudianteId: widget.asistencia.estudianteId,
                cursoId: widget.asistencia.cursoId,
                fecha: widget.asistencia.fecha,
                estado: estado,
                observacion: observacionController.text.isNotEmpty 
                    ? observacionController.text 
                    : null,
              );
              
              widget.onAsistenciaChanged(estado);
              Navigator.of(ctx).pop();
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }
  
  // Método para mostrar la observación existente
  void _mostrarObservacion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Observación - ${_getTituloEstado(widget.asistencia.estado)}',
          style: const TextStyle(fontSize: 18),
        ),
        content: Text(widget.asistencia.observacion ?? ''),
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

  // Obtener color según el estado de asistencia
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
  
  // Obtener título según el estado de asistencia
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