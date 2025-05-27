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
        // Navegar a detalle sin pasar datos adicionales
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => DetalleEstudianteScreen(
              estudianteId: estudiante.id.toString(),
            ),
          ),
        );
      },
      child: Row(
        children: [
          // Avatar del estudiante
          AvatarWidget(
            nombre: estudiante.nombre,
            apellido: estudiante.apellido,
            backgroundColor: Theme.of(context).primaryColor,
            radius: 28,
          ),
          const SizedBox(width: 16),
          
          // Información básica del estudiante
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
                Row(
                  children: [
                    Icon(
                      Icons.badge,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      estudiante.codigo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        estudiante.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Información del tutor (compacta)
                Row(
                  children: [
                    Expanded(
                      child: InfoChipWidget(
                        icon: Icons.person_outline,
                        text: estudiante.nombreTutor,
                        fontSize: 11,
                        iconSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InfoChipWidget(
                      icon: Icons.phone_outlined,
                      text: estudiante.telefonoTutor,
                      fontSize: 11,
                      iconSize: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Indicador de "ver más"
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}