import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/curso_provider.dart';
import '../../../providers/estudiantes_provider.dart';
import '../../../models/participacion.dart';

class RegistroParticipacionScreen extends StatefulWidget {
  static const routeName = '/participacion';

  const RegistroParticipacionScreen({Key? key}) : super(key: key);

  @override
  _RegistroParticipacionScreenState createState() =>
      _RegistroParticipacionScreenState();
}

class _RegistroParticipacionScreenState
    extends State<RegistroParticipacionScreen> {
  final DateTime _fecha = DateTime.now();
  final List<TipoParticipacion> _tiposParticipacion = TipoParticipacion.values;
  
  // Para simulación, guardamos participaciones locales
  final Map<String, List<Participacion>> _participaciones = {};

  @override
  Widget build(BuildContext context) {
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const Center(
        child: Text('Seleccione un curso para registrar participaciones'),
      );
    }

    final estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);

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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha actual',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_fecha),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: estudiantes.isEmpty
                ? const Center(child: Text('No hay estudiantes registrados'))
                : ListView.builder(
                    itemCount: estudiantes.length,
                    itemBuilder: (ctx, index) {
                      final estudiante = estudiantes[index];
                      
                      // Obtener participaciones del estudiante (simulado)
                      final participacionesEstudiante = 
                          _participaciones[estudiante.id] ?? [];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Text(
                                      estudiante.nombre.substring(0, 1) +
                                          estudiante.apellido.substring(0, 1),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Participaciones: ${participacionesEstudiante.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                children: _tiposParticipacion
                                    .map(
                                      (tipo) => ActionChip(
                                        avatar: CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: _getIconForTipo(tipo),
                                        ),
                                        label: Text(_getTipoText(tipo)),
                                        onPressed: () {
                                          _registrarParticipacion(
                                            estudiante.id,
                                            cursoSeleccionado.id,
                                            tipo,
                                          );
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              if (participacionesEstudiante.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Divider(),
                                const Text(
                                  'Participaciones de hoy:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...participacionesEstudiante
                                    .where((p) => 
                                        p.fecha.day == _fecha.day &&
                                        p.fecha.month == _fecha.month &&
                                        p.fecha.year == _fecha.year)
                                    .map((p) => ListTile(
                                          dense: true,
                                          leading: _getIconForTipo(p.tipo),
                                          title: Text(_getTipoText(p.tipo)),
                                          subtitle: Text(DateFormat('HH:mm').format(p.fecha)),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              _eliminarParticipacion(estudiante.id, p);
                                            },
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Guardar todas las participaciones
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Participaciones guardadas correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: const Icon(Icons.save),
        tooltip: 'Guardar participaciones',
      ),
    );
  }

  void _registrarParticipacion(
    String estudianteId,
    String cursoId,
    TipoParticipacion tipo,
  ) {
    final participacion = Participacion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      estudianteId: estudianteId,
      cursoId: cursoId,
      fecha: DateTime.now(),
      tipo: tipo,
    );

    setState(() {
      if (!_participaciones.containsKey(estudianteId)) {
        _participaciones[estudianteId] = [];
      }
      _participaciones[estudianteId]!.add(participacion);
    });
  }

  void _eliminarParticipacion(String estudianteId, Participacion participacion) {
    setState(() {
      _participaciones[estudianteId]!.remove(participacion);
    });
  }

  Icon _getIconForTipo(TipoParticipacion tipo) {
    switch (tipo) {
      case TipoParticipacion.pregunta:
        return const Icon(Icons.help_outline, color: Colors.blue);
      case TipoParticipacion.respuesta:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case TipoParticipacion.comentario:
        return const Icon(Icons.comment, color: Colors.orange);
      case TipoParticipacion.presentacion:
        return const Icon(Icons.slideshow, color: Colors.purple);
    }
  }

  String _getTipoText(TipoParticipacion tipo) {
    switch (tipo) {
      case TipoParticipacion.pregunta:
        return 'Pregunta';
      case TipoParticipacion.respuesta:
        return 'Respuesta';
      case TipoParticipacion.comentario:
        return 'Comentario';
      case TipoParticipacion.presentacion:
        return 'Presentación';
    }
  }
}