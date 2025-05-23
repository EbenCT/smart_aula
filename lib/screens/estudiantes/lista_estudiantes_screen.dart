import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../models/prediccion.dart';
import '../../screens/estudiantes/detalle_estudiante_screen.dart';

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
              'Seleccione un curso para ver los estudiantes',
              style: TextStyle(
                fontSize: 18, 
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
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
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar estudiante por nombre o código',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).iconTheme.color,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Lista de estudiantes
          Expanded(
            child: estudiantes.isEmpty
                ? Center(
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
                          'No hay estudiantes disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otro término de búsqueda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: estudiantes.length,
                    itemBuilder: (ctx, index) {
                      final estudiante = estudiantes[index];
                      final nivelPrediccion = estudiante.prediccion != null
                          ? NivelRendimiento.values.firstWhere(
                              (e) => e.toString().split('.').last == 
                                    estudiante.prediccion!['nivel'],
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

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: isDarkMode ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => DetalleEstudianteScreen(
                                  estudianteId: estudiante.id,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Primera fila: Avatar y nombre
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      radius: 24,
                                      child: Text(
                                        estudiante.nombre.substring(0, 1) +
                                            estudiante.apellido.substring(0, 1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: prediccionColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: estudiante.prediccion != null
                                            ? Text(
                                                estudiante.prediccion!['valorNumerico']
                                                    .toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.help_outline,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                      ),
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
                                          _buildInfoChip(
                                            context,
                                            Icons.school,
                                            'Promedio: ${estudiante.notas.isNotEmpty ? (estudiante.notas.values.reduce((a, b) => a + b) / estudiante.notas.length).toStringAsFixed(1) : 'N/A'}',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInfoChip(
                                            context,
                                            Icons.watch_later_outlined,
                                            'Asistencia: ${estudiante.porcentajeAsistencia.toStringAsFixed(0)}%',
                                          ),
                                        ],
                                      );
                                    }
                                    
                                    // Para pantallas más grandes, usar fila
                                    return Row(
                                      children: [
                                        Flexible(
                                          child: _buildInfoChip(
                                            context,
                                            Icons.school,
                                            'Promedio: ${estudiante.notas.isNotEmpty ? (estudiante.notas.values.reduce((a, b) => a + b) / estudiante.notas.length).toStringAsFixed(1) : 'N/A'}',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: _buildInfoChip(
                                            context,
                                            Icons.watch_later_outlined,
                                            'Asistencia: ${estudiante.porcentajeAsistencia.toStringAsFixed(0)}%',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Tercera fila: Etiqueta de predicción
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: prediccionColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: prediccionColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: 12,
                                        color: prediccionColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Predicción: ${_getNivelTexto(nivelPrediccion)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: prediccionColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 14,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getNivelTexto(NivelRendimiento nivel) {
    switch (nivel) {
      case NivelRendimiento.bajo:
        return 'Bajo';
      case NivelRendimiento.medio:
        return 'Medio';
      case NivelRendimiento.alto:
        return 'Alto';
    }
  }
}