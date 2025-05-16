import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/curso_provider.dart';
import '../../../providers/estudiantes_provider.dart';
import '../../../screens/estudiantes/detalle_estudiante_screen.dart';
import '../../models/estudiante.dart';
import '../../widgets/resumen_card.dart';

class DashboardScreen extends StatelessWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const Center(
        child: Text('Seleccione un curso para ver el dashboard'),
      );
    }

    final estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);
    
    if (estudiantes.isEmpty) {
      return const Center(
        child: Text('No hay estudiantes registrados en este curso'),
      );
    }

    // Calcular estadísticas
    final promedioNotas = _calcularPromedioNotas(estudiantes);
    final promedioAsistencia = _calcularPromedioAsistencia(estudiantes);
    final totalParticipaciones = _calcularTotalParticipaciones(estudiantes);
    
    // Estudiantes en riesgo (predicción baja)
    final estudiantesEnRiesgo = estudiantes.where((e) => 
      e.prediccion != null && 
      e.prediccion!['nivel'] == 'bajo'
    ).toList();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjetas de resumen
              Row(
                children: [
                  Expanded(
                    child: ResumenCard(
                      titulo: 'Estudiantes',
                      valor: estudiantes.length.toString(),
                      icono: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ResumenCard(
                      titulo: 'Promedio',
                      valor: promedioNotas.toStringAsFixed(1),
                      icono: Icons.school,
                      color: _getColorForNota(promedioNotas),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ResumenCard(
                      titulo: 'Asistencia',
                      valor: '${promedioAsistencia.toStringAsFixed(0)}%',
                      icono: Icons.calendar_today,
                      color: _getColorForAsistencia(promedioAsistencia),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ResumenCard(
                      titulo: 'Participaciones',
                      valor: totalParticipaciones.toString(),
                      icono: Icons.record_voice_over,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              
              // Estudiantes en riesgo
              if (estudiantesEnRiesgo.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Estudiantes en Riesgo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.red.shade50,
                  child: Column(
                    children: estudiantesEnRiesgo.map((estudiante) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Text(
                            estudiante.nombre.substring(0, 1) +
                                estudiante.apellido.substring(0, 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(estudiante.nombreCompleto),
                        subtitle: Text(
                          'Predicción: ${estudiante.prediccion!['valorNumerico']} - Factores: ${(estudiante.prediccion!['factoresInfluyentes'] as List).join(", ")}',
                        ),
                        trailing: const Icon(Icons.warning, color: Colors.red),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => DetalleEstudianteScreen(
                                estudianteId: estudiante.id,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              // Distribución de rendimiento
              const SizedBox(height: 24),
              const Text(
                'Distribución por Rendimiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildDistribucionItem(
                            context,
                            'Alto',
                            estudiantes.where((e) => 
                              e.prediccion != null && 
                              e.prediccion!['nivel'] == 'alto'
                            ).length,
                            estudiantes.length,
                            Colors.green,
                          ),
                          _buildDistribucionItem(
                            context,
                            'Medio',
                            estudiantes.where((e) => 
                              e.prediccion != null && 
                              e.prediccion!['nivel'] == 'medio'
                            ).length,
                            estudiantes.length,
                            Colors.amber,
                          ),
                          _buildDistribucionItem(
                            context,
                            'Bajo',
                            estudiantes.where((e) => 
                              e.prediccion != null && 
                              e.prediccion!['nivel'] == 'bajo'
                            ).length,
                            estudiantes.length,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'La distribución muestra la cantidad de estudiantes en cada categoría de rendimiento según las predicciones.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Estudiantes destacados
              const SizedBox(height: 24),
              const Text(
                'Estudiantes Destacados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.green.shade50,
                child: Column(
                  children: estudiantes
                      .where((e) => 
                        e.prediccion != null && 
                        e.prediccion!['nivel'] == 'alto'
                      )
                      .take(3)
                      .map((estudiante) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          estudiante.nombre.substring(0, 1) +
                              estudiante.apellido.substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(estudiante.nombreCompleto),
                      subtitle: Text(
                        'Predicción: ${estudiante.prediccion!['valorNumerico']} - Asistencia: ${estudiante.porcentajeAsistencia}%',
                      ),
                      trailing: const Icon(Icons.star, color: Colors.amber),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => DetalleEstudianteScreen(
                              estudianteId: estudiante.id,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Actualizar dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dashboard actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: const Icon(Icons.refresh),
        tooltip: 'Actualizar dashboard',
      ),
    );
  }

  Widget _buildDistribucionItem(
    BuildContext context,
    String titulo,
    int cantidad,
    int total,
    Color color,
  ) {
    final porcentaje = total > 0 ? (cantidad / total) * 100 : 0;
    
    return Expanded(
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade200,
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: porcentaje * 100 / 100,
                  width: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$cantidad',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${porcentaje.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  double _calcularPromedioNotas(List<Estudiante> estudiantes) {
    if (estudiantes.isEmpty) return 0;
    
    double sumaPromedios = 0;
    int estudiantesConNotas = 0;
    
    for (final estudiante in estudiantes) {
      if (estudiante.notas.isNotEmpty) {
        sumaPromedios += estudiante.notas.values.reduce((a, b) => a + b) / 
                         estudiante.notas.length;
        estudiantesConNotas++;
      }
    }
    
    return estudiantesConNotas > 0 ? sumaPromedios / estudiantesConNotas : 0;
  }

  double _calcularPromedioAsistencia(List<Estudiante> estudiantes) {
    if (estudiantes.isEmpty) return 0;
    
    double sumaAsistencia = 0;
    
    for (final estudiante in estudiantes) {
      sumaAsistencia += estudiante.porcentajeAsistencia;
    }
    
    return sumaAsistencia / estudiantes.length;
  }

  int _calcularTotalParticipaciones(List<Estudiante> estudiantes) {
    if (estudiantes.isEmpty) return 0;
    
    int totalParticipaciones = 0;
    
    for (final estudiante in estudiantes) {
      totalParticipaciones += estudiante.participaciones;
    }
    
    return totalParticipaciones;
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
}