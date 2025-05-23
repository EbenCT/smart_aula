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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 72,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccione un curso para ver el dashboard',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);
    
    if (estudiantes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay estudiantes registrados en este curso',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      color: Theme.of(context).primaryColor,
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
                Text(
                  'Estudiantes en Riesgo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: isDarkMode ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.red.withOpacity(isDarkMode ? 0.1 : 0.05),
                  child: Column(
                    children: estudiantesEnRiesgo.map((estudiante) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Text(
                              estudiante.nombre.substring(0, 1) +
                                  estudiante.apellido.substring(0, 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            estudiante.nombreCompleto,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Predicción: ${estudiante.prediccion!['valorNumerico']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Factores: ${(estudiante.prediccion!['factoresInfluyentes'] as List).join(", ")}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => DetalleEstudianteScreen(
                                  estudianteId: estudiante.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              // Distribución de rendimiento
              const SizedBox(height: 24),
              Text(
                'Distribución por Rendimiento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: isDarkMode ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      Text(
                        'La distribución muestra la cantidad de estudiantes en cada categoría de rendimiento según las predicciones.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Estudiantes destacados
              const SizedBox(height: 24),
              Text(
                'Estudiantes Destacados',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: isDarkMode ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.green.withOpacity(isDarkMode ? 0.1 : 0.05),
                child: Column(
                  children: estudiantes
                      .where((e) => 
                        e.prediccion != null && 
                        e.prediccion!['nivel'] == 'alto'
                      )
                      .take(3)
                      .map((estudiante) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            estudiante.nombre.substring(0, 1) +
                                estudiante.apellido.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          estudiante.nombreCompleto,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Predicción: ${estudiante.prediccion!['valorNumerico']} - Asistencia: ${estudiante.porcentajeAsistencia}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => DetalleEstudianteScreen(
                                estudianteId: estudiante.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 80), // Espacio para el FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Actualizar dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dashboard actualizado'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  height: porcentaje.toDouble(),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${porcentaje.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
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