import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/curso_provider.dart';
import '../../../models/curso.dart';
import '../../../models/materia.dart';

class SeleccionCursoMateriaScreen extends StatefulWidget {
  static const routeName = '/seleccion-curso-materia';

  const SeleccionCursoMateriaScreen({Key? key}) : super(key: key);

  @override
  _SeleccionCursoMateriaScreenState createState() =>
      _SeleccionCursoMateriaScreenState();
}

class _SeleccionCursoMateriaScreenState
    extends State<SeleccionCursoMateriaScreen> {
  int? _cursoSeleccionadoId;
  int? _materiaSeleccionadaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      
      // Cargar cursos del docente
      cursoProvider.cargarCursosDocente();
      
      // Si ya hay selecciones previas, mantenerlas
      if (cursoProvider.cursoSeleccionado != null) {
        setState(() {
          _cursoSeleccionadoId = cursoProvider.cursoSeleccionado!.id;
        });
      }
      
      if (cursoProvider.materiaSeleccionada != null) {
        setState(() {
          _materiaSeleccionadaId = cursoProvider.materiaSeleccionada!.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Curso y Materia'),
        elevation: 0,
      ),
      body: Consumer<CursoProvider>(
        builder: (context, cursoProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de curso
                const Text(
                  'Selecciona el curso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildCursoSelector(cursoProvider),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sección de materia
                const Text(
                  'Selecciona la materia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildMateriaSelector(cursoProvider),
                  ),
                ),
                
                // Información de selección actual
                if (cursoProvider.cursoSeleccionado != null || 
                    cursoProvider.materiaSeleccionada != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selección actual',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(cursoProvider.textoSeleccionActual),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Botón continuar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: cursoProvider.tieneSeleccionCompleta
                        ? () {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        : null,
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCursoSelector(CursoProvider cursoProvider) {
    if (cursoProvider.isLoadingCursos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (cursoProvider.errorMessage != null) {
      return Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            cursoProvider.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              cursoProvider.cargarCursosDocente();
            },
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (cursoProvider.cursos.isEmpty) {
      return const Column(
        children: [
          Icon(
            Icons.school_outlined,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'No tienes cursos asignados',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelText: 'Curso',
      ),
      value: _cursoSeleccionadoId,
      hint: const Text('Seleccione un curso'),
      isExpanded: true,
      items: cursoProvider.cursos.map((Curso curso) {
        return DropdownMenuItem<int>(
          value: curso.id,
          child: Text(
            '${curso.nombre} - ${curso.nivel} ${curso.paralelo} (${curso.turno})',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            _cursoSeleccionadoId = newValue;
            _materiaSeleccionadaId = null; // Limpiar selección de materia
          });
          cursoProvider.seleccionarCurso(newValue);
        }
      },
    );
  }

  Widget _buildMateriaSelector(CursoProvider cursoProvider) {
    if (_cursoSeleccionadoId == null) {
      return const Column(
        children: [
          Icon(
            Icons.book_outlined,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'Primero selecciona un curso',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    if (cursoProvider.isLoadingMaterias) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (cursoProvider.errorMessage != null && cursoProvider.materias.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Error al cargar materias',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_cursoSeleccionadoId != null) {
                cursoProvider.cargarMateriasCurso(_cursoSeleccionadoId!);
              }
            },
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (cursoProvider.materias.isEmpty) {
      return const Column(
        children: [
          Icon(
            Icons.book_outlined,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'No hay materias disponibles para este curso',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelText: 'Materia',
      ),
      value: _materiaSeleccionadaId,
      hint: const Text('Seleccione una materia'),
      isExpanded: true,
      items: cursoProvider.materias.map((Materia materia) {
        return DropdownMenuItem<int>(
          value: materia.id,
          child: Text(
            materia.descripcion.isNotEmpty 
                ? '${materia.nombre} - ${materia.descripcion}'
                : materia.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            _materiaSeleccionadaId = newValue;
          });
          cursoProvider.seleccionarMateria(newValue);
        }
      },
    );
  }
}