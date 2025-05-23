// lib/screens/participacion/registro_participacion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../models/participacion.dart';
import '../../models/estudiante.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/summary_stats_widget.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/student_list_item_widget.dart';
import '../../widgets/participation_type_selector_widget.dart';

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
  String _searchQuery = '';
  bool _localeInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Para simulación, guardamos participaciones locales
  final Map<String, List<Participacion>> _participaciones = {};
  
  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const EmptyStateWidget(
        icon: Icons.class_outlined,
        title: 'Seleccione un curso para registrar participaciones',
      );
    }

    var estudiantes = estudiantesProvider.estudiantesPorCurso(cursoSeleccionado.id);
    
    // Aplicar filtro si existe
    if (_searchQuery.isNotEmpty) {
      estudiantes = estudiantes.where((e) => 
        e.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.codigo.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Cabecera con fecha actual y filtro
          SearchHeaderWidget(
            hintText: 'Buscar estudiante...',
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            controller: _searchController,
            searchValue: _searchQuery,
            additionalWidget: DateSelectorWidget(
              selectedDate: _fecha,
              onDateChanged: (date) {}, // Fecha fija para hoy
              label: 'Fecha actual',
              localeInitialized: _localeInitialized,
            ),
          ),
          
          // Resumen de participaciones
          if (estudiantes.isNotEmpty)
            _buildParticipacionesSummary(estudiantes.length),
          
          // Lista de estudiantes
          Expanded(
            child: estudiantes.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'No hay estudiantes registrados',
                    subtitle: 'O no se encontraron estudiantes con el filtro actual',
                  )
                : _buildEstudiantesList(estudiantes, cursoSeleccionado.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarParticipaciones,
        icon: const Icon(Icons.save),
        label: const Text('Guardar'),
        tooltip: 'Guardar participaciones',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildParticipacionesSummary(int totalEstudiantes) {
    // Calcular estadísticas de participación
    int totalParticipaciones = 0;
    Map<TipoParticipacion, int> participacionesPorTipo = {};
    
    for (var tipo in TipoParticipacion.values) {
      participacionesPorTipo[tipo] = 0;
    }
    
    for (var participacionesEstudiante in _participaciones.values) {
      totalParticipaciones += participacionesEstudiante.length;
      for (var participacion in participacionesEstudiante) {
        participacionesPorTipo[participacion.tipo] = 
            (participacionesPorTipo[participacion.tipo] ?? 0) + 1;
      }
    }

    final stats = TipoParticipacion.values.map((tipo) => SummaryStat(
      title: _getTipoText(tipo),
      count: participacionesPorTipo[tipo] ?? 0,
      color: _getColorForTipo(tipo),
    )).toList();

    return SummaryStatsWidget(
      title: 'Resumen de Participaciones',
      stats: stats,
      additionalInfo: Row(
        children: [
          Expanded(
            child: Text(
              'Promedio: ${totalEstudiantes > 0 ? (totalParticipaciones / totalEstudiantes).toStringAsFixed(1) : 0} participaciones por estudiante',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
        
        return StudentListItemWidget(
          estudiante: estudiante,
          trailingWidget: _buildParticipacionesCounter(participacionesHoy.length),
          bottomWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de tipos de participación
              ParticipationTypeSelectorWidget(
                estudianteId: estudiante.id,
                cursoId: cursoId,
                onParticipationRegistered: _registrarParticipacion,
              ),
              
              // Lista de participaciones de hoy
              if (participacionesHoy.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Participaciones de hoy:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...participacionesHoy.map((p) => _buildParticipacionItem(estudiante.id, p)).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipacionesCounter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Hoy: $count',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildParticipacionItem(String estudianteId, Participacion participacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getColorForTipo(participacion.tipo).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _getColorForTipo(participacion.tipo).withOpacity(0.2),
            child: _getIconForTipo(participacion.tipo, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTipoText(participacion.tipo),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (participacion.descripcion != null && participacion.descripcion!.isNotEmpty)
                  Text(
                    participacion.descripcion!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
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

  void _guardarParticipaciones() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Participaciones guardadas correctamente'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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