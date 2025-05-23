import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../models/estudiante.dart';
import '../../screens/estudiantes/detalle_estudiante_screen.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/card_container_widget.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/info_chip_widget.dart';
import '../../widgets/prediction_indicator_widget.dart';

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
    return Consumer2<CursoProvider, EstudiantesProvider>(
      builder: (context, cursoProvider, estudiantesProvider, child) {
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;
        
        // Verificar si hay selección completa
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
                      Text(
                        '${estudiantes.length} estudiante(s)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
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
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: estudiantes.length,
                          itemBuilder: (ctx, index) {
                            final estudiante = estudiantes[index];
                            return _buildEstudianteCard(estudiante);
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

  Widget _buildEstudianteCard(Estudiante estudiante) {
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
          // Primera fila: Avatar, nombre y predicción
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
              // Indicador de predicción
              PredictionIndicatorWidget(
                prediccion: estudiante.prediccion,
                size: 40,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Segunda fila: Información académica (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              // Si el ancho es muy pequeño, usar columna
              if (constraints.maxWidth < 300) {
                return Column(
                  children: [
                    _buildPromedioChip(estudiante),
                    const SizedBox(height: 8),
                    _buildAsistenciaChip(estudiante),
                  ],
                );
              }
              
              // Para pantallas más grandes, usar fila
              return Row(
                children: [
                  Flexible(child: _buildPromedioChip(estudiante)),
                  const SizedBox(width: 8),
                  Flexible(child: _buildAsistenciaChip(estudiante)),
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
          
          // Cuarta fila: Etiqueta de predicción
          PredictionLabelWidget(prediccion: estudiante.prediccion),
        ],
      ),
    );
  }

  Widget _buildPromedioChip(Estudiante estudiante) {
    final promedio = _calcularPromedio(estudiante.notas);
    
    return InfoChipWidget(
      icon: Icons.school,
      text: 'Promedio: ${estudiante.notas.isNotEmpty ? promedio.toStringAsFixed(1) : 'N/A'}',
    );
  }

  Widget _buildAsistenciaChip(Estudiante estudiante) {
    return InfoChipWidget(
      icon: Icons.watch_later_outlined,
      text: 'Asistencia: ${estudiante.porcentajeAsistencia.toStringAsFixed(0)}%',
    );
  }

  double _calcularPromedio(Map<String, double> notas) {
    if (notas.isEmpty) return 0.0;
    
    double suma = 0.0;
    for (final nota in notas.values) {
      suma += nota;
    }
    return suma / notas.length;
  }
}