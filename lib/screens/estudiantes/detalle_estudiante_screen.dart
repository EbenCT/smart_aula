// lib/screens/estudiantes/detalle_estudiante_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/curso_provider.dart';
import '../../providers/resumen_estudiante_provider.dart';
import '../../providers/prediccion_completa_provider.dart';
import '../../models/resumen_estudiante.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/card_container_widget.dart';
import '../../widgets/prediccion_completa_widget.dart';

class DetalleEstudianteScreen extends StatefulWidget {
  final String estudianteId;

  const DetalleEstudianteScreen({
    Key? key,
    required this.estudianteId,
  }) : super(key: key);

  @override
  _DetalleEstudianteScreenState createState() => _DetalleEstudianteScreenState();
}

class _DetalleEstudianteScreenState extends State<DetalleEstudianteScreen> 
    with AutomaticKeepAliveClientMixin {
  
  ResumenEstudiante? _resumenEstudiante;
  bool _isLoadingResumen = false;
  String? _errorResumen;
  bool _dataLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosEstudiante();
    });
  }

  Future<void> _cargarDatosEstudiante() async {
    if (_dataLoaded) return;

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    
    if (!cursoProvider.tieneSeleccionCompleta) return;

    // Cargar resumen académico y precargar predicciones en paralelo
    await Future.wait([
      _cargarResumenEstudiante(),
      _precargarPredicciones(),
    ]);

    _dataLoaded = true;
  }

  Future<void> _cargarResumenEstudiante() async {
    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final resumenProvider = Provider.of<ResumenEstudianteProvider>(context, listen: false);
    
    if (!cursoProvider.tieneSeleccionCompleta) return;

    setState(() {
      _isLoadingResumen = true;
      _errorResumen = null;
    });

    try {
      final resumen = await resumenProvider.getResumenEstudiante(
        estudianteId: int.parse(widget.estudianteId),
        materiaId: cursoProvider.materiaSeleccionada!.id,
        periodoId: 1,
        forceRefresh: false, // Usar cache si está disponible
      );

      if (mounted) {
        setState(() {
          _resumenEstudiante = resumen;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorResumen = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingResumen = false;
        });
      }
    }
  }

  Future<void> _precargarPredicciones() async {
    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final prediccionProvider = Provider.of<PrediccionCompletaProvider>(context, listen: false);
    
    if (!cursoProvider.tieneSeleccionCompleta) return;

    try {
      // Precargar predicciones en background
      await prediccionProvider.precargarPredicciones(
        estudianteId: int.parse(widget.estudianteId),
        materiaId: cursoProvider.materiaSeleccionada!.id,
        gestionId: 2,
      );
    } catch (e) {
      // Fallar silenciosamente en precarga
      debugPrint('Error precargando predicciones: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataLoaded = false;
    });
    
    final resumenProvider = Provider.of<ResumenEstudianteProvider>(context, listen: false);
    final prediccionProvider = Provider.of<PrediccionCompletaProvider>(context, listen: false);
    
    // Limpiar cache para forzar recarga
    resumenProvider.clearStudentCache(int.parse(widget.estudianteId));
    prediccionProvider.invalidarCache(
      estudianteId: int.parse(widget.estudianteId),
      materiaId: Provider.of<CursoProvider>(context, listen: false).materiaSeleccionada?.id,
      gestionId: 2,
    );
    
    await _cargarDatosEstudiante();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Datos del estudiante actualizados'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer2<EstudiantesProvider, CursoProvider>(
      builder: (context, estudiantesProvider, cursoProvider, child) {
        final estudiante = estudiantesProvider.getEstudiantePorId(int.parse(widget.estudianteId));

        if (estudiante == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Estudiante no encontrado'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 72,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'El estudiante no fue encontrado',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(estudiante.nombreCompleto),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                tooltip: 'Actualizar datos',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Encabezado con información básica del estudiante
                  _buildHeaderSection(context, estudiante),
                  
                  // Predicciones de Machine Learning (nueva sección)
                  if (cursoProvider.tieneSeleccionCompleta)
                    PrediccionCompletaWidget(
                      estudianteId: int.parse(widget.estudianteId),
                      materiaId: cursoProvider.materiaSeleccionada!.id,
                      gestionId: 2,
                    ),
                  
                  // Resumen académico
                  _buildResumenAcademico(context),
                  
                  // Información personal
                  _buildInformacionPersonalCard(context, estudiante),
                  
                  // Información del tutor
                  _buildInformacionTutorCard(context, estudiante),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, estudiante) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          AvatarWidget(
            nombre: estudiante.nombre,
            apellido: estudiante.apellido,
            radius: 60,
            backgroundColor: Colors.white,
            textColor: Theme.of(context).primaryColor,
            fontSize: 48,
          ),
          const SizedBox(height: 20),
          Text(
            estudiante.nombreCompleto,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              estudiante.codigo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                estudiante.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenAcademico(BuildContext context) {
    return CardContainerWidget(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rendimiento Académico',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              if (_isLoadingResumen)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isLoadingResumen)
            _buildLoadingEstado()
          else if (_errorResumen != null)
            _buildErrorEstado()
          else if (_resumenEstudiante != null)
            _buildResumenCompleto()
          else
            _buildSinDatos(),
        ],
      ),
    );
  }

  Widget _buildLoadingEstado() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando estadísticas académicas...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorEstado() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Error al cargar estadísticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorResumen ?? 'Error desconocido',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarResumenEstudiante,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinDatos() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin datos académicos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay evaluaciones registradas para este estudiante en la materia actual.',
            style: TextStyle(
              color: Colors.orange.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCompleto() {
    final resumen = _resumenEstudiante!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Promedio general destacado
        if (resumen.tieneEvaluaciones) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getColorForNota(resumen.promedioGeneral).withOpacity(0.15),
                  _getColorForNota(resumen.promedioGeneral).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getColorForNota(resumen.promedioGeneral).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getColorForNota(resumen.promedioGeneral),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getColorForNota(resumen.promedioGeneral).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      resumen.promedioGeneral.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promedio General',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTextoRendimiento(resumen.promedioGeneral, false),
                        style: TextStyle(
                          color: _getColorForNota(resumen.promedioGeneral),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${resumen.evaluacionesAcademicas.length} tipos de evaluación',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Asistencia (si existe)
        if (resumen.tieneAsistencia) ...[
          _buildAsistenciaCard(resumen.asistencia!),
          const SizedBox(height: 24),
        ],
        
        // Evaluaciones académicas
        if (resumen.tieneEvaluaciones) ...[
          Text(
            'Detalle por Tipo de Evaluación',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...resumen.evaluacionesAcademicas.map((evaluacion) => 
            _buildEvaluacionCard(context, evaluacion)
          ).toList(),
        ],
      ],
    );
  }

  Widget _buildAsistenciaCard(TipoEvaluacion asistencia) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getColorForAsistencia(asistencia.porcentaje ?? 0).withOpacity(0.15),
            _getColorForAsistencia(asistencia.porcentaje ?? 0).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getColorForAsistencia(asistencia.porcentaje ?? 0).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getColorForAsistencia(asistencia.porcentaje ?? 0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(asistencia.porcentaje ?? 0).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistencia',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getTextoRendimiento(asistencia.porcentaje ?? 0, true),
                      style: TextStyle(
                        color: _getColorForAsistencia(asistencia.porcentaje ?? 0),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${asistencia.total} registros',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (asistencia.porcentaje ?? 0) / 100,
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
            color: _getColorForAsistencia(asistencia.porcentaje ?? 0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          
          // Registros recientes
          if (asistencia.detalle.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Registros Recientes:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...asistencia.detalle.take(3).map((detalle) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getColorForValorAsistencia(detalle.valor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      detalle.descripcion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    _formatearFecha(detalle.fecha),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildEvaluacionCard(BuildContext context, TipoEvaluacion evaluacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorForNota(evaluacion.valorPrincipal).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getColorForNota(evaluacion.valorPrincipal),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  evaluacion.valorPrincipal.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evaluacion.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${evaluacion.total} evaluación(es) • ${evaluacion.textoRendimiento}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getColorForNota(evaluacion.valorPrincipal),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Mostrar detalle si hay evaluaciones
          if (evaluacion.detalle.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Evaluaciones:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...evaluacion.detalle.take(5).map((detalle) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getColorForNota(detalle.valor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      detalle.descripcion,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    detalle.valor.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForNota(detalle.valor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatearFecha(detalle.fecha),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )).toList(),
            
            if (evaluacion.detalle.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Y ${evaluacion.detalle.length - 5} evaluación(es) más...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInformacionPersonalCard(BuildContext context, estudiante) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(
            context,
            'Fecha de Nacimiento',
            DateFormat('dd/MM/yyyy').format(estudiante.fechaNacimiento),
            Icons.cake_rounded,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            'Género',
            estudiante.genero,
            Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            'Edad',
            '${_calcularEdad(estudiante.fechaNacimiento)} años',
            Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            'Dirección',
            estudiante.direccionCasa,
            Icons.home_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionTutorCard(BuildContext context, estudiante) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.family_restroom_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Información del Tutor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(
            context,
            'Nombre del Tutor',
            estudiante.nombreTutor,
            Icons.person_rounded,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            'Teléfono',
            estudiante.telefonoTutor,
            Icons.phone_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Llamar a ${estudiante.telefonoTutor}'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  action: SnackBarAction(
                    label: 'Cerrar',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    Widget content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }

  int _calcularEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return DateFormat('dd/MM').format(dateTime);
    } catch (e) {
      return fecha;
    }
  }

  Color _getColorForNota(double nota) {
    if (nota >= 80) {
      return Colors.green;
    } else if (nota >= 60) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  Color _getColorForAsistencia(double porcentaje) {
    if (porcentaje >= 90) {
      return Colors.green;
    } else if (porcentaje >= 75) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  Color _getColorForValorAsistencia(double valor) {
    if (valor >= 100) {
      return Colors.green; // Presente
    } else if (valor >= 75) {
      return Colors.blue; // Justificado
    } else if (valor >= 50) {
      return Colors.amber; // Tardanza
    } else {
      return Colors.red; // Ausente
    }
  }

  String _getTextoRendimiento(double valor, bool esAsistencia) {
    if (esAsistencia) {
      if (valor >= 90) return 'Excelente';
      if (valor >= 75) return 'Bueno';
      return 'Deficiente';
    } else {
      if (valor >= 80) return 'Excelente';
      if (valor >= 60) return 'Bueno';
      return 'Necesita mejorar';
    }
  }
}