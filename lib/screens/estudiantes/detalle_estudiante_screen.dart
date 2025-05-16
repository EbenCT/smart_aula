import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/estudiantes_provider.dart';
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

    final nivelPrediccion = estudiante.prediccion != null
        ? NivelRendimiento.values.firstWhere(
            (e) => e.toString().split('.').last == estudiante.prediccion!['nivel'],
            orElse: () => NivelRendimiento.medio,
          )
        : NivelRendimiento.medio;

    Color prediccionColor;
    switch (nivelPrediccion) {
      case NivelRendimiento.bajo:
        prediccionColor = Colors.red;
        break;
      case NivelRendimiento.medio:
        prediccionColor = Colors.amber;
        break;
      case NivelRendimiento.alto:
        prediccionColor = Colors.green;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(estudiante.nombreCompleto),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado con información básica
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      estudiante.nombre.substring(0, 1) +
                          estudiante.apellido.substring(0, 1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
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
            ),
            // Tarjeta de predicción
            if (estudiante.prediccion != null)
              Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: prediccionColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    estudiante.prediccion!['valorNumerico']
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Text(
                                    _getNivelTexto(nivelPrediccion),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                    .map((factor) => Padding(
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
                      const Text(
                        'La predicción se basa en el historial académico, asistencia y participación del estudiante.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Tarjeta de rendimiento académico
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: estudiante.notas.length,
                            itemBuilder: (ctx, index) {
                              final entry = estudiante.notas.entries.elementAt(index);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatEvaluacionNombre(entry.key),
                                    ),
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
                            },
                          ),
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
                            color: _getColorForNota(
                              estudiante.notas.isEmpty
                                  ? 0
                                  : estudiante.notas.values.reduce((a, b) => a + b) /
                                      estudiante.notas.length,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            estudiante.notas.isEmpty
                                ? 'N/A'
                                : (estudiante.notas.values.reduce((a, b) => a + b) /
                                        estudiante.notas.length)
                                    .toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Tarjeta de asistencia y participación
            Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                                backgroundColor: Colors.grey.shade300,
                                color: _getColorForAsistencia(
                                    estudiante.porcentajeAsistencia),
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
                                    _getTextoAsistencia(
                                        estudiante.porcentajeAsistencia),
                                    style: TextStyle(
                                      color: _getColorForAsistencia(
                                          estudiante.porcentajeAsistencia),
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
                                    _getTextoParticipacion(
                                        estudiante.participaciones),
                                    style: TextStyle(
                                      color: _getColorForParticipacion(
                                          estudiante.participaciones),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNivelTexto(NivelRendimiento nivel) {
    switch (nivel) {
      case NivelRendimiento.bajo:
        return 'BAJO';
      case NivelRendimiento.medio:
        return 'MEDIO';
      case NivelRendimiento.alto:
        return 'ALTO';
    }
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