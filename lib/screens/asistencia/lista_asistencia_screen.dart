import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importar esto para la inicialización de locales
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
  String? _filtro;
  bool _localeInitialized = false;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar asistencia: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor, 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
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

  void _filtrarEstudiantes(String? valor) {
    setState(() {
      _filtro = valor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cursoProvider = Provider.of<CursoProvider>(context);
    final estudiantesProvider = Provider.of<EstudiantesProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    
    final cursoSeleccionado = cursoProvider.cursoSeleccionado;
    
    if (cursoSeleccionado == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Seleccione un curso para ver la asistencia',
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
    
    final asistencias = asistenciaProvider.asistenciasPorCursoYFecha(
      cursoSeleccionado.id, 
      _fechaSeleccionada
    );

    // Calcular resumen de asistencia
    int totalEstudiantes = estudiantes.length;
    int presentes = asistencias.where((a) => a.estado == EstadoAsistencia.presente).length;
    int tardanzas = asistencias.where((a) => a.estado == EstadoAsistencia.tardanza).length;
    int ausentes = asistencias.where((a) => a.estado == EstadoAsistencia.ausente).length;
    int justificados = asistencias.where((a) => a.estado == EstadoAsistencia.justificado).length;

    return Scaffold(
      body: Column(
        children: [
          // Cabecera con fecha y filtro
          _buildHeader(),
          
          // Resumen de asistencia
          if (totalEstudiantes > 0)
            _buildAsistenciaSummary(presentes, tardanzas, ausentes, justificados, totalEstudiantes),
          
          // Lista de estudiantes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : estudiantes.isEmpty
                    ? _buildEmptyState()
                    : _buildEstudiantesList(estudiantes, asistencias, cursoSeleccionado.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asistencias guardadas correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: const Icon(Icons.save),
        label: const Text('Guardar'),
        tooltip: 'Guardar asistencias',
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
          // Selector de fecha
          GestureDetector(
            onTap: () => _seleccionarFecha(context),
            child: Container(
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
                        'Fecha de clase',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _localeInitialized 
                          ? DateFormat('EEEE, dd MMMM yyyy', 'es').format(_fechaSeleccionada)
                          : DateFormat('yyyy-MM-dd').format(_fechaSeleccionada), // Formato simple si no se ha inicializado
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
          ),
          const SizedBox(height: 12),
          
          // Buscador/Filtro
          TextField(
            onChanged: _filtrarEstudiantes,
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

  Widget _buildAsistenciaSummary(int presentes, int tardanzas, int ausentes, int justificados, int total) {
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
              'Resumen de Asistencia',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Presentes', presentes, Colors.green),
                _buildSummaryItem('Tardes', tardanzas, Colors.amber),
                _buildSummaryItem('Ausentes', ausentes, Colors.red),
                _buildSummaryItem('Justificados', justificados, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? (presentes + tardanzas + justificados) / total : 0,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Asistencia general: ${total > 0 ? ((presentes + tardanzas + justificados) * 100 / total).toStringAsFixed(0) : "0"}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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

  Widget _buildEstudiantesList(
    List<dynamic> estudiantes,
    List<Asistencia> asistencias,
    String cursoId,
  ) {
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: estudiantes.length,
      itemBuilder: (ctx, index) {
        final estudiante = estudiantes[index];
        final asistencia = asistencias.firstWhere(
          (a) => a.estudianteId == estudiante.id,
          orElse: () => Asistencia(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            estudianteId: estudiante.id,
            cursoId: cursoId,
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
              cursoId: cursoId,
              fecha: _fechaSeleccionada,
              estado: nuevoEstado,
              observacion: asistencia.observacion,
            );
            
            asistenciaProvider.registrarAsistencia(nuevaAsistencia);
          },
        );
      },
    );
  }
}