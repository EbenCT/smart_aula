// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/estudiantes_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/card_container_widget.dart';
import '../../widgets/prediction_indicator_widget.dart';
import '../../../models/prediccion.dart';

class DetalleEstudianteScreen extends StatelessWidget {
  final String estudianteId;

  const DetalleEstudianteScreen({
    Key? key,
    required this.estudianteId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    final estudiante = estudiantesProvider.getEstudiantePorId(estudianteId);

    return Scaffold(
      appBar: AppBar(
        title: Text(estudiante.nombreCompleto),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado con información básica
            _buildHeaderSection(context, estudiante),
            
            // Tarjeta de predicción
            if (estudiante.prediccion != null)
              _buildPrediccionCard(context, estudiante),
            
            // Tarjeta de rendimiento académico
            _buildRendimientoCard(context, estudiante),
            
            // Tarjeta de asistencia y participación
            _buildAsistenciaParticipacionCard(context, estudiante),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, estudiante) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          AvatarWidget(
            nombre: estudiante.nombre,
            apellido: estudiante.apellido,
            radius: 40,
            backgroundColor: Colors.white,
            textColor: Theme.of(context).primaryColor,
            fontSize: 32,
          ),
          const SizedBox(height: 16),
          Text(
            estudiante.nombreCompleto,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            estudiante.codigo,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estudiante.email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrediccionCard(BuildContext context, estudiante) {
    final nivel = NivelRendimiento.values.firstWhere(
      (e) => e.toString().split('.').last == estudiante.prediccion!['nivel'],
      orElse: () => NivelRendimiento.medio,
    );

    return CardContainerWidget(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predicción de Rendimiento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              PredictionIndicatorWidget(
                prediccion: estudiante.prediccion,
                size: 80,
                showLabel: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Factores Influyentes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List<String>.from(estudiante.prediccion!['factoresInfluyentes'])
                        .map<Widget>((factor) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_right, size: 16),
                                  Expanded(child: Text(factor)),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'La predicción se basa en el historial académico, asistencia y participación del estudiante.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRendimientoCard(BuildContext context, estudiante) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rendimiento Académico',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notas:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          estudiante.notas.isEmpty
              ? const Text('No hay notas registradas')
              : Column(
                  children: estudiante.notas.entries.map<Widget>((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatEvaluacionNombre(entry.key)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorForNota(entry.value),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          if (estudiante.notas.isNotEmpty) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Promedio General:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getColorForNota(_calcularPromedio(estudiante.notas)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _calcularPromedio(estudiante.notas).toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAsistenciaParticipacionCard(BuildContext context, estudiante) {
    return CardContainerWidget(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asistencia y Participación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Asistencia
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Porcentaje de Asistencia:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: estudiante.porcentajeAsistencia / 100,
                      backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                      color: _getColorForAsistencia(estudiante.porcentajeAsistencia),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${estudiante.porcentajeAsistencia.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTextoAsistencia(estudiante.porcentajeAsistencia),
                          style: TextStyle(
                            color: _getColorForAsistencia(estudiante.porcentajeAsistencia),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Participación
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Participaciones en clase:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${estudiante.participaciones}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTextoParticipacion(estudiante.participaciones),
                          style: TextStyle(
                            color: _getColorForParticipacion(estudiante.participaciones),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEvaluacionNombre(String key) {
    // Convierte "parcial1" a "Parcial 1"
    final regex = RegExp(r'([a-zA-Z]+)(\d+)');
    final match = regex.firstMatch(key);
    if (match != null) {
      final palabra = match.group(1)!;
      final numero = match.group(2)!;
      return '${palabra[0].toUpperCase()}${palabra.substring(1)} $numero';
    }
    return key;
  }

  double _calcularPromedio(Map<String, double> notas) {
    if (notas.isEmpty) return 0.0;
    
    double suma = 0.0;
    for (final nota in notas.values) {
      suma += nota;
    }
    return suma / notas.length;
  }

  Color _getColorForNota(double nota) {
    if (nota >= 80) {
      return Colors.green;
    } else if (nota >= 60) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  Color _getColorForAsistencia(double porcentaje) {
    if (porcentaje >= 90) {
      return Colors.green;
    } else if (porcentaje >= 75) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  String _getTextoAsistencia(double porcentaje) {
    if (porcentaje >= 90) {
      return 'Excelente';
    } else if (porcentaje >= 75) {
      return 'Regular';
    } else {
      return 'Deficiente';
    }
  }

  Color _getColorForParticipacion(int cantidad) {
    if (cantidad >= 10) {
      return Colors.green;
    } else if (cantidad >= 5) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  String _getTextoParticipacion(int cantidad) {
    if (cantidad >= 10) {
      return 'Alto';
    } else if (cantidad >= 5) {
      return 'Medio';
    } else {
      return 'Bajo';
    }
  }
}