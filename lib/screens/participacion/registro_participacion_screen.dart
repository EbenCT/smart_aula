import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importar esto para la inicialización de locales
import '../../../providers/curso_provider.dart';
import '../../../providers/estudiantes_provider.dart';
import '../../../models/participacion.dart';
import '../../../models/estudiante.dart';

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
  String? _filtro;
  bool _localeInitialized = false;
  
  // Para simulación, guardamos participaciones locales
  final Map<String, List<Participacion>> _participaciones = {};
  
  @override
  void initState() {
    super.initState();
    // Inicializar los datos de localización
    initializeDateFormatting('es', null).then((_) {
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Seleccione un curso para registrar participaciones',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    var estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);
    
    // Aplicar filtro si existe
    if (_filtro != null && _filtro!.isNotEmpty) {
      estudiantes = estudiantes.where((e) => 
        e.nombreCompleto.toLowerCase().contains(_filtro!.toLowerCase()) ||
        e.codigo.toLowerCase().contains(_filtro!.toLowerCase())
      ).toList();
    }

    // Calcular estadísticas de participación
    int totalParticipaciones = 0;
    for (var participacionesEstudiante in _participaciones.values) {
      totalParticipaciones += participacionesEstudiante.length;
    }
    
    // Calcular participaciones por tipo
    Map<TipoParticipacion, int> participacionesPorTipo = {};
    for (var tipo in _tiposParticipacion) {
      participacionesPorTipo[tipo] = 0;
    }
    
    for (var participacionesEstudiante in _participaciones.values) {
      for (var participacion in participacionesEstudiante) {
        participacionesPorTipo[participacion.tipo] = 
            (participacionesPorTipo[participacion.tipo] ?? 0) + 1;
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // Cabecera con fecha y filtro
          _buildHeader(),
          
          // Resumen de participaciones
          if (estudiantes.isNotEmpty)
            _buildParticipacionesSummary(totalParticipaciones, participacionesPorTipo, estudiantes.length),
          
          // Lista de estudiantes
          Expanded(
            child: estudiantes.isEmpty
                ? _buildEmptyState()
                : _buildEstudiantesList(estudiantes, cursoSeleccionado.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Participaciones guardadas correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: const Icon(Icons.save),
        label: const Text('Guardar'),
        tooltip: 'Guardar participaciones',
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fecha actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha actual',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localeInitialized 
                        ? DateFormat('EEEE, dd MMMM yyyy', 'es').format(_fecha)
                        : DateFormat('yyyy-MM-dd').format(_fecha), // Formato simple si no se ha inicializado
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Buscador/Filtro
          TextField(
            onChanged: (value) {
              setState(() {
                _filtro = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar estudiante...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipacionesSummary(
    int totalParticipaciones,
    Map<TipoParticipacion, int> participacionesPorTipo,
    int totalEstudiantes
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Participaciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total',
                  totalParticipaciones,
                  Theme.of(context).primaryColor,
                ),
                ..._tiposParticipacion.map((tipo) => _buildSummaryItem(
                  _getTipoText(tipo),
                  participacionesPorTipo[tipo] ?? 0,
                  _getColorForTipo(tipo),
                )).toList(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Promedio: ${totalEstudiantes > 0 ? (totalParticipaciones / totalEstudiantes).toStringAsFixed(1) : 0} participaciones por estudiante',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay estudiantes registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O no se encontraron estudiantes con el filtro actual',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudiantesList(List<Estudiante> estudiantes, String cursoId) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: estudiantes.length,
      itemBuilder: (ctx, index) {
        final estudiante = estudiantes[index];
        
        // Obtener participaciones del estudiante
        final participacionesEstudiante = _participaciones[estudiante.id] ?? [];
        
        // Participaciones de hoy
        final participacionesHoy = participacionesEstudiante.where((p) => 
          p.fecha.year == _fecha.year && 
          p.fecha.month == _fecha.month && 
          p.fecha.day == _fecha.day
        ).toList();
        
        return _buildEstudianteCard(estudiante, participacionesHoy, cursoId);
      },
    );
  }

  Widget _buildEstudianteCard(
    Estudiante estudiante, 
    List<Participacion> participacionesHoy,
    String cursoId
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del estudiante
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.purple.shade100,
                  child: Text(
                    estudiante.nombre.substring(0, 1) +
                    estudiante.apellido.substring(0, 1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${estudiante.codigo}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hoy: ${participacionesHoy.length}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botones de tipo de participación
            _buildTiposParticipacion(estudiante.id, cursoId),
            
            // Lista de participaciones de hoy
            if (participacionesHoy.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                'Participaciones de hoy:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...participacionesHoy.map((p) => _buildParticipacionItem(estudiante.id, p)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTiposParticipacion(String estudianteId, String cursoId) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tiposParticipacion.map((tipo) {
        return _buildTipoParticipacionChip(estudianteId, cursoId, tipo);
      }).toList(),
    );
  }

  Widget _buildTipoParticipacionChip(String estudianteId, String cursoId, TipoParticipacion tipo) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: _getColorForTipo(tipo).withOpacity(0.2),
        child: _getIconForTipo(tipo),
      ),
      label: Text(_getTipoText(tipo)),
      backgroundColor: Colors.white,
      side: BorderSide(color: _getColorForTipo(tipo).withOpacity(0.5)),
      onPressed: () {
        _mostrarDialogoRegistroParticipacion(estudianteId, cursoId, tipo);
      },
    );
  }

  Widget _buildParticipacionItem(String estudianteId, Participacion participacion) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: _getColorForTipo(participacion.tipo).withOpacity(0.2),
        child: _getIconForTipo(participacion.tipo, size: 16),
      ),
      title: Text(
        _getTipoText(participacion.tipo),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: participacion.descripcion != null && participacion.descripcion!.isNotEmpty
          ? Text(
              participacion.descripcion!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Valor: ${participacion.valoracion}',
            style: TextStyle(
              color: _getColorForValoracion(participacion.valoracion),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () {
              _eliminarParticipacion(estudianteId, participacion);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRegistroParticipacion(
    String estudianteId, 
    String cursoId, 
    TipoParticipacion tipo
  ) {
    final TextEditingController descripcionController = TextEditingController();
    int valoracion = 3; // Valor predeterminado
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Registrar ${_getTipoText(tipo)}',
              style: const TextStyle(fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descripción (opcional):',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Participación sobre el tema X',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Valoración:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: valoracion.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: valoracion.toString(),
                  activeColor: _getColorForValoracion(valoracion),
                  onChanged: (newValue) {
                    setState(() {
                      valoracion = newValue.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Baja', style: TextStyle(fontSize: 12)),
                    Text(
                      valoracion.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorForValoracion(valoracion),
                      ),
                    ),
                    const Text('Alta', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () {
                  _registrarParticipacion(
                    estudianteId,
                    cursoId,
                    tipo,
                    descripcionController.text,
                    valoracion,
                  );
                  Navigator.of(ctx).pop();
                },
                child: const Text('GUARDAR'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _registrarParticipacion(
    String estudianteId,
    String cursoId,
    TipoParticipacion tipo,
    String descripcion,
    int valoracion,
  ) {
    final participacion = Participacion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      estudianteId: estudianteId,
      cursoId: cursoId,
      fecha: DateTime.now(),
      tipo: tipo,
      descripcion: descripcion.isNotEmpty ? descripcion : null,
      valoracion: valoracion,
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

  Icon _getIconForTipo(TipoParticipacion tipo, {double size = 20}) {
    switch (tipo) {
      case TipoParticipacion.pregunta:
        return Icon(Icons.help_outline, color: Colors.blue, size: size);
      case TipoParticipacion.respuesta:
        return Icon(Icons.check_circle_outline, color: Colors.green, size: size);
      case TipoParticipacion.comentario:
        return Icon(Icons.comment, color: Colors.orange, size: size);
      case TipoParticipacion.presentacion:
        return Icon(Icons.slideshow, color: Colors.purple, size: size);
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
  
  Color _getColorForTipo(TipoParticipacion tipo) {
    switch (tipo) {
      case TipoParticipacion.pregunta:
        return Colors.blue;
      case TipoParticipacion.respuesta:
        return Colors.green;
      case TipoParticipacion.comentario:
        return Colors.orange;
      case TipoParticipacion.presentacion:
        return Colors.purple;
    }
  }
  
  Color _getColorForValoracion(int valoracion) {
    if (valoracion >= 4) {
      return Colors.green;
    } else if (valoracion >= 3) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }
}