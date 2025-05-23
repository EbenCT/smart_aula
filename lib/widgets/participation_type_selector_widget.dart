// lib/widgets/participation_type_selector_widget.dart
import 'package:flutter/material.dart';
import '../models/participacion.dart';

class ParticipationTypeSelectorWidget extends StatelessWidget {
  final String estudianteId;
  final String cursoId;
  final Function(String, String, TipoParticipacion, String, int) onParticipationRegistered;

  const ParticipationTypeSelectorWidget({
    Key? key,
    required this.estudianteId,
    required this.cursoId,
    required this.onParticipationRegistered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TipoParticipacion.values.map((tipo) {
        return _buildTipoParticipacionChip(context, tipo);
      }).toList(),
    );
  }

  Widget _buildTipoParticipacionChip(BuildContext context, TipoParticipacion tipo) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: _getColorForTipo(tipo).withOpacity(0.2),
        child: _getIconForTipo(tipo),
      ),
      label: Text(_getTipoText(tipo)),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(color: _getColorForTipo(tipo).withOpacity(0.5)),
      onPressed: () {
        _mostrarDialogoRegistroParticipacion(context, tipo);
      },
    );
  }

  void _mostrarDialogoRegistroParticipacion(BuildContext context, TipoParticipacion tipo) {
    final TextEditingController descripcionController = TextEditingController();
    int valoracion = 3; // Valor predeterminado
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Text(
              'Registrar ${_getTipoText(tipo)}',
              style: const TextStyle(fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descripción (opcional):',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Participación sobre el tema X',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Valoración:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: valoracion.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: valoracion.toString(),
                  activeColor: _getColorForValoracion(valoracion),
                  onChanged: (newValue) {
                    setState(() {
                      valoracion = newValue.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Baja', style: TextStyle(fontSize: 12)),
                    Text(
                      valoracion.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorForValoracion(valoracion),
                      ),
                    ),
                    const Text('Alta', style: TextStyle(fontSize: 12)),
                  ],
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
                  onParticipationRegistered(
                    estudianteId,
                    cursoId,
                    tipo,
                    descripcionController.text,
                    valoracion,
                  );
                  Navigator.of(ctx).pop();
                },
                child: const Text('GUARDAR'),
              ),
            ],
          );
        },
      ),
    );
  }

  Icon _getIconForTipo(TipoParticipacion tipo, {double size = 20}) {
    switch (tipo) {
      case TipoParticipacion.pregunta:
        return Icon(Icons.help_outline, color: Colors.blue, size: size);
      case TipoParticipacion.respuesta:
        return Icon(Icons.check_circle_outline, color: Colors.green, size: size);
      case TipoParticipacion.comentario:
        return Icon(Icons.comment, color: Colors.orange, size: size);
      case TipoParticipacion.presentacion:
        return Icon(Icons.slideshow, color: Colors.purple, size: size);
    }
  }

  String _getTipoText(TipoParticipacion tipo) {
    switch (tipo) {
      case TipoParticipacion.pregunta:
        return 'Pregunta';
      case TipoParticipacion.respuesta:
        return 'Respuesta';
      case TipoParticipacion.comentario:
        return 'Comentario';
      case TipoParticipacion.presentacion:
        return 'Presentación';
    }
  }
  
  Color _getColorForTipo(TipoParticipacion tipo) {
    switch (tipo) {
      case TipoParticipacion.pregunta:
        return Colors.blue;
      case TipoParticipacion.respuesta:
        return Colors.green;
      case TipoParticipacion.comentario:
        return Colors.orange;
      case TipoParticipacion.presentacion:
        return Colors.purple;
    }
  }
  
  Color _getColorForValoracion(int valoracion) {
    if (valoracion >= 4) {
      return Colors.green;
    } else if (valoracion >= 3) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }
}