// lib/screens/estudiantes/detalle_materia_estudiante_screen.dart
// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/resumen_estudiante_provider.dart';
import '../../providers/prediccion_completa_provider.dart';
import '../../models/resumen_estudiante.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/card_container_widget.dart';
import '../../widgets/prediccion_completa_widget.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';

class DetalleMateriasEstudianteScreen extends StatefulWidget {
  final String estudianteId;
  final int materiaId;
  final int cursoId;
  final String materiaNombre;
  final String cursoNombre;

  const DetalleMateriasEstudianteScreen({
    Key? key,
    required this.estudianteId,
    required this.materiaId,
    required this.cursoId,
    required this.materiaNombre,
    required this.cursoNombre,
  }) : super(key: key);

  @override
  _DetalleMateriasEstudianteScreenState createState() => _DetalleMateriasEstudianteScreenState();
}

class _DetalleMateriasEstudianteScreenState extends State<DetalleMateriasEstudianteScreen> 
    with AutomaticKeepAliveClientMixin {
  
  ResumenEstudiante? _resumenEstudiante;
  bool _isLoadingResumen = false;
  String? _errorResumen;
  bool _dataLoaded = false;
  Map<String, dynamic>? _estudianteInfo;
  late ApiService _apiService;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosEstudiante();
    });
  }

  Future<void> _cargarDatosEstudiante() async {
    if (_dataLoaded) return;

    // Cargar resumen académico y precargar predicciones en paralelo
    await Future.wait([
      _cargarResumenEstudiante(),
      _precargarPredicciones(),
      _cargarInfoEstudiante(),
    ]);

    _dataLoaded = true;
  }

  Future<void> _cargarInfoEstudiante() async {
    try {
      // Obtener información básica del estudiante desde el dashboard
      final dashboard = await _apiService.getDashboardEstudiante();
      if (dashboard['success'] == true) {
        setState(() {
          _estudianteInfo = dashboard['estudiante'];
        });
      }
    } catch (e) {
      debugPrint('Error cargando info del estudiante: $e');
    }
  }

  Future<void> _cargarResumenEstudiante() async {
    final resumenProvider = Provider.of<ResumenEstudianteProvider>(context, listen: false);
    
    setState(() {
      _isLoadingResumen = true;
      _errorResumen = null;
    });

    try {
      final resumen = await resumenProvider.getResumenEstudiante(
        estudianteId: int.parse(widget.estudianteId),
        materiaId: widget.materiaId,
        periodoId: 1,
        forceRefresh: false,
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
    final prediccionProvider = Provider.of<PrediccionCompletaProvider>(context, listen: false);
    
    try {
      await prediccionProvider.precargarPredicciones(
        estudianteId: int.parse(widget.estudianteId),
        materiaId: widget.materiaId,
        gestionId: 2,
      );
    } catch (e) {
      debugPrint('Error precargando predicciones: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataLoaded = false;
    });
    
    final resumenProvider = Provider.of<ResumenEstudianteProvider>(context, listen: false);
    final prediccionProvider = Provider.of<PrediccionCompletaProvider>(context, listen: false);
    
    resumenProvider.clearStudentCache(int.parse(widget.estudianteId));
    prediccionProvider.invalidarCache(
      estudianteId: int.parse(widget.estudianteId),
      materiaId: widget.materiaId,
      gestionId: 2,
    );
    
    await _cargarDatosEstudiante();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Datos actualizados'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

   void _mostrarDialogoEnviarCorreo() {
    final TextEditingController correoController = TextEditingController();
    bool enviando = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Row(
            children: [
              Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Enviar Reporte por Correo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingrese el correo electrónico donde desea recibir el reporte (opcional):',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: correoController,
                decoration: InputDecoration(
                  hintText: 'correo@ejemplo.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'Si no ingresa un correo, se enviará al correo del usuario logueado',
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
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
                      child: Text(
                        'El reporte incluirá predicciones de Machine Learning',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: enviando ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: enviando ? null : () {
                _enviarReportePorCorreo(correoController.text.trim(), setState);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: enviando 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Enviar Reporte'),
            ),
          ],
        ),
      ),
    );
  }

  // Método para realizar la llamada API de envío de correo
  Future<void> _enviarReportePorCorreo(String correoPersonalizado, StateSetter setState) async {
    setState(() {
      // Esta variable debe ser declarada en el StatefulBuilder para controlar el estado de carga
    });

    try {
      // Obtener el token de autenticación
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;
      
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Preparar la URL con parámetros
      final baseUrl = '${AppConstants.apiBaseUrl}/info-academica/enviar-reporte-por-correo';
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'estudiante_id': widget.estudianteId,
        'incluir_predicciones': 'true',
        if (correoPersonalizado.isNotEmpty) 'correo_personalizado': correoPersonalizado,
      });

      print('Enviando reporte a: $uri'); // Para debug

      // Realizar la llamada POST
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));

      // Cerrar el diálogo
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        // Éxito - mostrar mensaje de confirmación
        _mostrarMensajeExito(correoPersonalizado);
      } else {
        // Error del servidor
        String errorMessage = 'Error al enviar el reporte';
        try {
          final responseData = json.decode(response.body);
          errorMessage = responseData['detail'] ?? responseData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Error del servidor (${response.statusCode})';
        }
        throw Exception(errorMessage);
      }

    } catch (e) {
      // Cerrar el diálogo si hay error
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Mostrar mensaje de error
      _mostrarMensajeError(e.toString());
    }
  }

  // Método para mostrar mensaje de éxito
  void _mostrarMensajeExito(String correoPersonalizado) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final correoDestino = correoPersonalizado.isNotEmpty 
        ? correoPersonalizado 
        : authService.correo ?? 'su correo registrado';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Reporte Enviado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El reporte académico ha sido enviado exitosamente a:',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      correoDestino,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'El reporte incluye información académica completa y predicciones de rendimiento.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Método para mostrar mensaje de error
  void _mostrarMensajeError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error al enviar reporte: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _mostrarDialogoEnviarCorreo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_estudianteInfo != null 
                ? '${_estudianteInfo!['nombre']} ${_estudianteInfo!['apellido']}'
                : 'Estudiante'
            ),
            Text(
              widget.materiaNombre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
              if (_estudianteInfo != null)
                _buildHeaderSection(context),
              
              // Predicciones de Machine Learning
              PrediccionCompletaWidget(
                estudianteId: int.parse(widget.estudianteId),
                materiaId: widget.materiaId,
                gestionId: 2,
              ),
              
              // Resumen académico
              _buildResumenAcademico(context),
              
              // Información de la materia
              _buildInformacionMateriaCard(context),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
          // NUEVO: Botón flotante siempre visible
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _mostrarDialogoEnviarCorreo,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.email_outlined),
      label: const Text('ENVIAR CORREO REPORTE'),
      tooltip: 'Enviar reporte académico por correo electrónico',
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
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
            nombre: _estudianteInfo!['nombre'],
            apellido: _estudianteInfo!['apellido'],
            radius: 60,
            backgroundColor: Colors.white,
            textColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '${_estudianteInfo!['nombre']} ${_estudianteInfo!['apellido']}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.materiaNombre,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenAcademico(BuildContext context) {
    return CardContainerWidget(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Resumen Académico',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingResumen) 
            _buildCargandoResumen()
          else if (_errorResumen != null) 
            _buildErrorResumen()
          else if (_resumenEstudiante == null) 
            _buildSinDatos()
          else 
            _buildResumenCompleto(),
        ],
      ),
    );
  }

  Widget _buildCargandoResumen() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando resumen académico...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorResumen() {
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
            'Error al cargar datos',
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
            'No hay evaluaciones registradas para esta materia.',
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
                  ),
                  child: Center(
                    child: Text(
                      resumen.promedioGeneral.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                        'Promedio General',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTextoRendimiento(resumen.promedioGeneral),
                        style: TextStyle(
                          color: _getColorForNota(resumen.promedioGeneral),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  Widget _buildEvaluacionCard(BuildContext context, evaluacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorForNota(evaluacion.valorPrincipal ?? 0).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                evaluacion.nombre,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForNota(evaluacion.valorPrincipal ?? 0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  evaluacion.valorPrincipal?.toStringAsFixed(1) ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ${evaluacion.total} registros',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (evaluacion.porcentaje != null)
                Text(
                  '${evaluacion.porcentaje!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getColorForNota(evaluacion.porcentaje!),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionMateriaCard(BuildContext context) {
    return CardContainerWidget(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book, color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Información de la Materia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Materia', widget.materiaNombre),
          _buildInfoRow('Curso', widget.cursoNombre),
          _buildInfoRow('ID de Materia', widget.materiaId.toString()),
          _buildInfoRow('ID de Curso', widget.cursoId.toString()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de utilidad para colores (reutilizados del archivo original)
  Color _getColorForNota(double nota) {
    if (nota >= 70) return Colors.green;
    if (nota >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getTextoRendimiento(double promedio) {
    if (promedio >= 90) return 'EXCELENTE';
    if (promedio >= 80) return 'MUY BUENO';
    if (promedio >= 70) return 'BUENO';
    if (promedio >= 60) return 'REGULAR';
    return 'NECESITA MEJORAR';
  }
}