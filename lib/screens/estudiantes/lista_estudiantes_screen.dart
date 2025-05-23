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
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const EmptyStateWidget(
        icon: Icons.class_outlined,
        title: 'Seleccione un curso para ver los estudiantes',
      );
    }

    var estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      estudiantes = estudiantes.where((estudiante) {
        return estudiante.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            estudiante.codigo.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda
          SearchHeaderWidget(
            hintText: 'Buscar estudiante por nombre o código',
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            controller: _searchController,
            searchValue: _searchQuery,
          ),
          
          // Lista de estudiantes
          Expanded(
            child: estudiantes.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'No hay estudiantes disponibles',
                    subtitle: _searchQuery.isNotEmpty 
                        ? 'Intenta con otro término de búsqueda'
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: estudiantes.length,
                    itemBuilder: (ctx, index) {
                      final estudiante = estudiantes[index];
                      return _buildEstudianteCard(estudiante);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudianteCard(Estudiante estudiante) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => DetalleEstudianteScreen(
              estudianteId: estudiante.id,
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
          
          // Tercera fila: Etiqueta de predicción
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