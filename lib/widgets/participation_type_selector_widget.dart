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
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _mostrarDialogoParticipacion(context);
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Agregar Participación'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoParticipacion(BuildContext context) {
    final TextEditingController descripcionController = TextEditingController();
    int puntaje = 50; // Valor inicial (50/100)
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Row(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Registrar Participación',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de descripción
                  Text(
                    'Descripción (opcional):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descripcionController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Participó activamente en la discusión sobre...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Selector de puntaje
                  Text(
                    'Puntaje de participación:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Slider para el puntaje
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getColorForPuntaje(puntaje).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorForPuntaje(puntaje),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$puntaje/100',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: puntaje.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20, // Incrementos de 5
                          label: puntaje.toString(),
                          activeColor: _getColorForPuntaje(puntaje),
                          onChanged: (newValue) {
                            setState(() {
                              puntaje = newValue.round();
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              _getTextForPuntaje(puntaje),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getColorForPuntaje(puntaje),
                              ),
                            ),
                            Text(
                              '100',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botones de puntaje rápido
                  Text(
                    'Puntajes rápidos:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickScoreButton(context, setState, 25, 'Básico', puntaje),
                      _buildQuickScoreButton(context, setState, 50, 'Regular', puntaje),
                      _buildQuickScoreButton(context, setState, 75, 'Bueno', puntaje),
                      _buildQuickScoreButton(context, setState, 100, 'Excelente', puntaje),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'CANCELAR',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final descripcion = descripcionController.text.trim().isEmpty 
                      ? 'Participación' 
                      : descripcionController.text.trim();
                  
                  // Usamos TipoParticipacion.comentario por defecto (que representa participación general)
                  onParticipationRegistered(
                    estudianteId,
                    cursoId,
                    TipoParticipacion.comentario,
                    descripcion,
                    puntaje, // Ahora es 0-100 en lugar de 1-5
                  );
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('GUARDAR'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickScoreButton(
    BuildContext context,
    StateSetter setState,
    int score,
    String label,
    int currentScore,
  ) {
    final isSelected = currentScore == score;
    
    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Necesitamos una manera de actualizar el puntaje en el scope padre
            // Para esto, necesitamos pasar el puntaje por referencia
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? _getColorForPuntaje(score).withOpacity(0.2)
                : Colors.transparent,
            border: Border.all(
              color: isSelected 
                  ? _getColorForPuntaje(score)
                  : Theme.of(context).dividerColor.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? _getColorForPuntaje(score)
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected 
                      ? _getColorForPuntaje(score)
                      : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForPuntaje(int puntaje) {
    if (puntaje >= 85) {
      return Colors.green;
    } else if (puntaje >= 70) {
      return Colors.lightGreen;
    } else if (puntaje >= 50) {
      return Colors.amber;
    } else if (puntaje >= 25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getTextForPuntaje(int puntaje) {
    if (puntaje >= 85) {
      return 'Excelente';
    } else if (puntaje >= 70) {
      return 'Muy Bueno';
    } else if (puntaje >= 50) {
      return 'Bueno';
    } else if (puntaje >= 25) {
      return 'Regular';
    } else {
      return 'Básico';
    }
  }

  // Métodos mantenidos para compatibilidad con código anterior
  Icon _getIconForTipo(TipoParticipacion tipo, {double size = 20}) {
    return Icon(Icons.record_voice_over, color: Colors.blue, size: size);
  }

  String _getTipoText(TipoParticipacion tipo) {
    return 'Participación';
  }
  
  Color _getColorForTipo(TipoParticipacion tipo) {
    return Colors.blue;
  }
  
  Color _getColorForValoracion(int valoracion) {
    return _getColorForPuntaje(valoracion);
  }
}