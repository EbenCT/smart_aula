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
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const Center(
        child: Text('Seleccione un curso para ver los estudiantes'),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar estudiante por nombre o código',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
          Expanded(
            child: estudiantes.isEmpty
                ? const Center(child: Text('No hay estudiantes disponibles'))
                : ListView.builder(
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
                          vertical: 8,
                        ),
                        child: InkWell(
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
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    estudiante.nombre.substring(0, 1) +
                                        estudiante.apellido.substring(0, 1),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        estudiante.nombreCompleto,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        estudiante.codigo,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.school, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Promedio: ${estudiante.notas.isNotEmpty ? (estudiante.notas.values.reduce((a, b) => a + b) / estudiante.notas.length).toStringAsFixed(1) : 'N/A'}',
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.watch_later_outlined, size: 16),
                                          const SizedBox(width: 4),
                                          Text('Asistencia: ${estudiante.porcentajeAsistencia.toStringAsFixed(0)}%'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
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
                                                ),
                                              )
                                            : const Icon(
                                                Icons.help_outline,
                                                color: Colors.white,
                                              ),
                                              ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Predicción',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
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
}