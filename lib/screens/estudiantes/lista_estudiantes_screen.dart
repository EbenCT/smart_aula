import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/resumen_estudiante_provider.dart';
import '../../models/estudiante.dart';
import '../../screens/estudiantes/detalle_estudiante_screen.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/card_container_widget.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/info_chip_widget.dart';

class ListaEstudiantesScreen extends StatefulWidget {
  static const routeName = '/estudiantes';

  const ListaEstudiantesScreen({Key? key}) : super(key: key);

  @override
  _ListaEstudiantesScreenState createState() => _ListaEstudiantesScreenState();
}

class _ListaEstudiantesScreenState extends State<ListaEstudiantesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CursoProvider, EstudiantesProvider, ResumenEstudianteProvider>(
      builder: (context, cursoProvider, estudiantesProvider, resumenProvider, child) {
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;
        
        if (!cursoProvider.tieneSeleccionCompleta) {
          return const EmptyStateWidget(
            icon: Icons.class_outlined,
            title: 'Seleccione un curso y una materia para ver los estudiantes',
          );
        }

        // Cargar estudiantes cuando hay selección completa
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cursoSeleccionado != null && materiaSeleccionada != null) {
            estudiantesProvider.cargarEstudiantesPorMateria(
              cursoSeleccionado.id, 
              materiaSeleccionada.id
            );
            
            // Precargar resúmenes de estudiantes
            if (estudiantesProvider.estudiantes.isNotEmpty) {
              final estudianteIds = estudiantesProvider.estudiantes.map((e) => e.id).toList();
              resumenProvider.preloadEstudiantesResumen(
                estudianteIds: estudianteIds,
                materiaId: materiaSeleccionada.id,
                periodoId: 1, // Puedes ajustar esto según tu lógica de periodos
              );
            }
          }
        });

        // Estado de carga
        if (estudiantesProvider.isLoading) {
          return Scaffold(
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando estudiantes...'),
                ],
              ),
            ),
          );
        }

        // Estado de error
        if (estudiantesProvider.errorMessage != null) {
          return Scaffold(
            body: Center(
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
                    estudiantesProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      estudiantesProvider.recargarEstudiantes();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        // Filtrar estudiantes por búsqueda
        var estudiantes = _searchQuery.isEmpty 
            ? estudiantesProvider.estudiantes
            : estudiantesProvider.buscarEstudiantes(_searchQuery);

        return Scaffold(
          body: Column(
            children: [
              // Barra de búsqueda con información de la materia
              SearchHeaderWidget(
                hintText: 'Buscar estudiante por nombre o código',
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                controller: _searchController,
                searchValue: _searchQuery,
                additionalWidget: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              materiaSeleccionada!.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              cursoSeleccionado!.nombreCompleto,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${estudiantes.length} estudiante(s)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          if (resumenProvider.isLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Lista de estudiantes
              Expanded(
                child: estudiantes.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: _searchQuery.isNotEmpty 
                            ? 'No se encontraron estudiantes'
                            : 'No hay estudiantes registrados',
                        subtitle: _searchQuery.isNotEmpty 
                            ? 'Intenta con otro término de búsqueda'
                            : 'No hay estudiantes registrados en esta materia',
                        action: _searchQuery.isNotEmpty 
                            ? ElevatedButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Text('Limpiar búsqueda'),
                              )
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await estudiantesProvider.recargarEstudiantes();
                          // Limpiar cache y recargar resúmenes
                          resumenProvider.clearCache();
                          if (estudiantesProvider.estudiantes.isNotEmpty) {
                            final estudianteIds = estudiantesProvider.estudiantes.map((e) => e.id).toList();
                            await resumenProvider.preloadEstudiantesResumen(
                              estudianteIds: estudianteIds,
                              materiaId: materiaSeleccionada.id,
                              periodoId: 1,
                            );
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: estudiantes.length,
                          itemBuilder: (ctx, index) {
                            final estudiante = estudiantes[index];
                            return _buildEstudianteCard(
                              estudiante, 
                              materiaSeleccionada.id,
                              resumenProvider,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstudianteCard(
    Estudiante estudiante, 
    int materiaId,
    ResumenEstudianteProvider resumenProvider,
  ) {
    // Obtener estadísticas del resumen
    final estadisticas = resumenProvider.getEstadisticasRapidas(
      estudianteId: estudiante.id,
      materiaId: materiaId,
      periodoId: 1,
    );

    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => DetalleEstudianteScreen(
              estudianteId: estudiante.id.toString(),
            ),
          ),
        );
      },
      child: Column(
        children: [
          // Primera fila: Avatar, nombre y indicadores de rendimiento
          Row(
            children: [
              AvatarWidget(
                nombre: estudiante.nombre,
                apellido: estudiante.apellido,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estudiante.nombreCompleto,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estudiante.codigo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      estudiante.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Indicador de progreso general
              _buildIndicadorRendimiento(estadisticas),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Segunda fila: Estadísticas académicas
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                return Column(
                  children: [
                    _buildPromedioChip(estadisticas),
                    const SizedBox(height: 8),
                    _buildAsistenciaChip(estadisticas),
                  ],
                );
              }
              
              return Row(
                children: [
                  Flexible(child: _buildPromedioChip(estadisticas)),
                  const SizedBox(width: 8),
                  Flexible(child: _buildAsistenciaChip(estadisticas)),
                ],
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // Tercera fila: Información del tutor
          Row(
            children: [
              Expanded(
                child: InfoChipWidget(
                  icon: Icons.person_outline,
                  text: 'Tutor: ${estudiante.nombreTutor}',
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InfoChipWidget(
                  icon: Icons.phone_outlined,
                  text: estudiante.telefonoTutor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Cuarta fila: Indicador de estado del resumen
          _buildEstadoResumen(estadisticas),
        ],
      ),
    );
  }

  Widget _buildIndicadorRendimiento(Map<String, dynamic> estadisticas) {
    final tieneResumen = estadisticas['tieneResumen'] as bool;
    final promedio = estadisticas['promedioGeneral'] as double;
    
    if (!tieneResumen) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.help_outline,
          color: Colors.grey,
          size: 20,
        ),
      );
    }

    final color = _getColorForNota(promedio);
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              promedio.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Text(
              'PROM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromedioChip(Map<String, dynamic> estadisticas) {
    final tieneResumen = estadisticas['tieneResumen'] as bool;
    final promedio = estadisticas['promedioGeneral'] as double;
    final totalEvaluaciones = estadisticas['totalEvaluaciones'] as int;
    
    return InfoChipWidget(
      icon: Icons.school,
      text: tieneResumen 
          ? 'Promedio: ${promedio.toStringAsFixed(1)} ($totalEvaluaciones eval.)'
          : 'Promedio: Cargando...',
      color: tieneResumen ? _getColorForNota(promedio) : Colors.grey,
    );
  }

  Widget _buildAsistenciaChip(Map<String, dynamic> estadisticas) {
    final tieneResumen = estadisticas['tieneResumen'] as bool;
    final asistencia = estadisticas['porcentajeAsistencia'] as double;
    
    return InfoChipWidget(
      icon: Icons.calendar_today,
      text: tieneResumen 
          ? 'Asistencia: ${asistencia.toStringAsFixed(0)}%'
          : 'Asistencia: Cargando...',
      color: tieneResumen ? _getColorForAsistencia(asistencia) : Colors.grey,
    );
  }

  Widget _buildEstadoResumen(Map<String, dynamic> estadisticas) {
    final tieneResumen = estadisticas['tieneResumen'] as bool;
    
    if (!tieneResumen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync,
              size: 14,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'Cargando estadísticas...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Estadísticas actualizadas',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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