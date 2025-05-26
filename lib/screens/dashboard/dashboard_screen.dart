import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/curso_provider.dart';
import '../../../providers/estudiantes_provider.dart';
import '../../../providers/resumen_provider.dart';
import '../../../screens/estudiantes/detalle_estudiante_screen.dart';
import '../../models/estudiante.dart';
import '../../models/resumen_materia.dart';
import '../../widgets/resumen_card.dart';

class DashboardScreen extends StatelessWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<CursoProvider, EstudiantesProvider, ResumenProvider>(
      builder: (context, cursoProvider, estudiantesProvider, resumenProvider, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;
        
        if (!cursoProvider.tieneSeleccionCompleta) {
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
                  'Seleccione un curso y una materia para ver el dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Cargar resumen cuando hay selección completa
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cursoSeleccionado != null && materiaSeleccionada != null) {
            resumenProvider.cargarResumenMateria(
              cursoSeleccionado.id, 
              materiaSeleccionada.id
            );
            estudiantesProvider.cargarEstudiantesPorMateria(
              cursoSeleccionado.id, 
              materiaSeleccionada.id
            );
          }
        });

        // Estado de carga del resumen
        if (resumenProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando resumen...'),
              ],
            ),
          );
        }
        
        // Estado de error del resumen
        if (resumenProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 72,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  resumenProvider.errorMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    resumenProvider.recargarResumen();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final resumenMateria = resumenProvider.resumenMateria;
        final estudiantes = estudiantesProvider.estudiantes;
        
        if (resumenMateria == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 72,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay datos de resumen disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del curso y materia actual
                  _buildHeaderCard(context, cursoSeleccionado!, materiaSeleccionada!, isDarkMode),
                  
                  const SizedBox(height: 16),
                  
                  // Tarjetas de resumen principales
                  _buildMainStatsCards(context, resumenMateria),
                  
                  const SizedBox(height: 16),
                  
                  // Tarjetas de promedios detallados
                  _buildDetailedStatsCards(context, resumenMateria),
                  
                  // Información por periodo (si hay múltiples periodos)
                  if (resumenMateria.resumenPorPeriodo.length > 1) ...[
                    const SizedBox(height: 24),
                    _buildPeriodosSection(context, resumenMateria),
                  ],
                  
                  // Estudiantes (si están disponibles)
                  if (estudiantes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildEstudiantesSection(context, estudiantes, isDarkMode),
                  ],
                  
                  // Análisis de datos disponibles
                  const SizedBox(height: 24),
                  _buildAnalisisSection(context, resumenMateria, isDarkMode),
                  
                  const SizedBox(height: 80), // Espacio para el FAB
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              resumenProvider.recargarResumen();
              if (estudiantesProvider.tieneEstudiantesCargados) {
                estudiantesProvider.recargarEstudiantes();
              }
              
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
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, curso, materia, bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.school,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia.nombre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    curso.nombreCompleto,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsCards(BuildContext context, ResumenMateriaCompleto resumen) {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: 'Estudiantes',
            valor: resumen.totalEstudiantes.toString(),
            icono: Icons.people,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Asistencia',
            valor: '${resumen.promedioGeneral.asistencia.toStringAsFixed(1)}%',
            icono: Icons.calendar_today,
            color: _getColorForAsistencia(resumen.promedioGeneral.asistencia),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStatsCards(BuildContext context, ResumenMateriaCompleto resumen) {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: resumen.tieneNotas ? 'Promedio Notas' : 'Sin Notas',
            valor: resumen.tieneNotas 
                ? resumen.promedioGeneral.notas.toStringAsFixed(1)
                : 'N/A',
            icono: Icons.school,
            color: resumen.tieneNotas 
                ? _getColorForNota(resumen.promedioGeneral.notas)
                : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Participación',
            valor: resumen.promedioGeneral.participacion.toStringAsFixed(2),
            icono: Icons.record_voice_over,
            color: _getColorForParticipacion(resumen.promedioGeneral.participacion),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodosSection(BuildContext context, ResumenMateriaCompleto resumen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen por Períodos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...resumen.resumenPorPeriodo.map((periodo) => 
          _buildPeriodoCard(context, periodo)
        ).toList(),
      ],
    );
  }

  Widget _buildPeriodoCard(BuildContext context, ResumenPorPeriodo periodo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período ${periodo.periodoId}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Notas',
                    periodo.promedioNotas > 0 
                        ? periodo.promedioNotas.toStringAsFixed(1)
                        : 'N/A',
                    Icons.school,
                    periodo.promedioNotas > 0 
                        ? _getColorForNota(periodo.promedioNotas)
                        : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Asistencia',
                    '${periodo.promedioAsistencia.toStringAsFixed(1)}%',
                    Icons.calendar_today,
                    _getColorForAsistencia(periodo.promedioAsistencia),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Participación',
                    periodo.promedioParticipacion.toStringAsFixed(2),
                    Icons.record_voice_over,
                    _getColorForParticipacion(periodo.promedioParticipacion),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEstudiantesSection(BuildContext context, List<Estudiante> estudiantes, bool isDarkMode) {
    // Mostrar solo los primeros 5 estudiantes en el dashboard
    final estudiantesMuestra = estudiantes.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estudiantes Recientes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navegar a la lista completa de estudiantes
                Navigator.of(context).pushNamed('/estudiantes');
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: isDarkMode ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: estudiantesMuestra.map((estudiante) {
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
                    backgroundColor: Theme.of(context).primaryColor,
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
                    'Código: ${estudiante.codigo}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => DetalleEstudianteScreen(
                          estudianteId: estudiante.id.toString(),
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
    );
  }

  Widget _buildAnalisisSection(BuildContext context, ResumenMateriaCompleto resumen, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis de Datos',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Estado de los Datos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Indicadores de disponibilidad de datos
                _buildDataIndicator(
                  context,
                  'Notas',
                  resumen.tieneNotas,
                  resumen.tieneNotas 
                      ? 'Promedio: ${resumen.promedioGeneral.notas.toStringAsFixed(1)}'
                      : 'No hay calificaciones registradas',
                  Icons.school,
                ),
                const SizedBox(height: 12),
                
                _buildDataIndicator(
                  context,
                  'Asistencia',
                  resumen.tieneAsistencia,
                  'Promedio: ${resumen.promedioGeneral.asistencia.toStringAsFixed(1)}%',
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                
                _buildDataIndicator(
                  context,
                  'Participación',
                  resumen.tieneParticipacion,
                  'Promedio: ${resumen.promedioGeneral.participacion.toStringAsFixed(2)}',
                  Icons.record_voice_over,
                ),
                
                const SizedBox(height: 16),
                
                // Recomendaciones
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recomendaciones',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(_getRecomendaciones(resumen).map((recomendacion) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  recomendacion,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        )
                      ).toList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataIndicator(BuildContext context, String title, bool hasData, String description, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasData ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasData ? Icons.check : Icons.warning_outlined,
            color: hasData ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getRecomendaciones(ResumenMateriaCompleto resumen) {
    List<String> recomendaciones = [];

    if (!resumen.tieneNotas) {
      recomendaciones.add('Considera registrar calificaciones para obtener un análisis más completo del rendimiento académico.');
    }

    if (resumen.promedioGeneral.asistencia < 75) {
      recomendaciones.add('La asistencia está por debajo del 75%. Implementa estrategias para mejorar la participación.');
    } else if (resumen.promedioGeneral.asistencia > 90) {
      recomendaciones.add('¡Excelente asistencia! Mantén las estrategias que están funcionando.');
    }

    if (resumen.promedioGeneral.participacion < 0.5) {
      recomendaciones.add('La participación es baja. Considera implementar actividades más interactivas en clase.');
    }

    if (resumen.tieneNotas && resumen.promedioGeneral.notas < 60) {
      recomendaciones.add('El promedio de notas indica la necesidad de reforzar ciertos temas o métodos de enseñanza.');
    }

    if (recomendaciones.isEmpty) {
      recomendaciones.add('Los indicadores muestran un buen desempeño general. Continúa con las estrategias actuales.');
    }

    return recomendaciones;
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

  Color _getColorForParticipacion(double promedio) {
    if (promedio >= 1.0) {
      return Colors.green;
    } else if (promedio >= 0.5) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }
}