import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/asistencia_provider.dart';
import '../../../providers/estudiantes_provider.dart';
import '../../../providers/curso_provider.dart';
import '../../../models/asistencia.dart';
import '../../widgets/asistencia_item.dart';

class ListaAsistenciaScreen extends StatefulWidget {
  static const routeName = '/asistencia';

  const ListaAsistenciaScreen({Key? key}) : super(key: key);

  @override
  _ListaAsistenciaScreenState createState() => _ListaAsistenciaScreenState();
}

class _ListaAsistenciaScreenState extends State<ListaAsistenciaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarAsistencia();
    });
  }

  Future<void> _cargarAsistencia() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      
      if (cursoProvider.cursoSeleccionado != null) {
        asistenciaProvider.setCursoId(cursoProvider.cursoSeleccionado!.id);
        asistenciaProvider.setFechaSeleccionada(_fechaSeleccionada);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar asistencia: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null && fechaSeleccionada != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = fechaSeleccionada;
      });
      Provider.of<AsistenciaProvider>(context, listen: false)
          .setFechaSeleccionada(fechaSeleccionada);
      _cargarAsistencia();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const Center(
        child: Text('Seleccione un curso para ver la asistencia'),
      );
    }

    final estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);
    final asistencias = asistenciaProvider.asistenciasPorCursoYFecha(
      cursoSeleccionado.id, 
      _fechaSeleccionada
    );

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () => _seleccionarFecha(context),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _cargarAsistencia,
                    tooltip: 'Recargar',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : estudiantes.isEmpty
                    ? const Center(child: Text('No hay estudiantes registrados'))
                    : ListView.builder(
                        itemCount: estudiantes.length,
                        itemBuilder: (ctx, index) {
                          final estudiante = estudiantes[index];
                          final asistencia = asistencias.firstWhere(
                            (a) => a.estudianteId == estudiante.id,
                            orElse: () => Asistencia(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              estudianteId: estudiante.id,
                              cursoId: cursoSeleccionado.id,
                              fecha: _fechaSeleccionada,
                              estado: EstadoAsistencia.ausente,
                            ),
                          );
                          
                          return AsistenciaItem(
                            estudiante: estudiante,
                            asistencia: asistencia,
                            onAsistenciaChanged: (EstadoAsistencia nuevoEstado) {
                              final nuevaAsistencia = Asistencia(
                                id: asistencia.id,
                                estudianteId: estudiante.id,
                                cursoId: cursoSeleccionado.id,
                                fecha: _fechaSeleccionada,
                                estado: nuevoEstado,
                                observacion: asistencia.observacion,
                              );
                              
                              asistenciaProvider.registrarAsistencia(nuevaAsistencia);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Guardar todas las asistencias
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asistencias guardadas correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: const Icon(Icons.save),
        tooltip: 'Guardar asistencias',
      ),
    );
  }
}