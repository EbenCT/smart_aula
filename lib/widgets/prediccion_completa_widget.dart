// lib/widgets/prediccion_completa_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prediccion_completa.dart';
import '../providers/prediccion_completa_provider.dart';
import '../widgets/card_container_widget.dart';
import '../utils/debug_logger.dart';

class PrediccionCompletaWidget extends StatefulWidget {
  final int estudianteId;
  final int materiaId;
  final int gestionId;

  const PrediccionCompletaWidget({
    Key? key,
    required this.estudianteId,
    required this.materiaId,
    this.gestionId = 2,
  }) : super(key: key);

  @override
  _PrediccionCompletaWidgetState createState() => _PrediccionCompletaWidgetState();
}

class _PrediccionCompletaWidgetState extends State<PrediccionCompletaWidget> {
  List<PrediccionCompleta>? _predicciones;
  Map<String, dynamic>? _estadisticas;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPredicciones();
    });
  }

  Future<void> _cargarPredicciones() async {
    if (!mounted) return;

    DebugLogger.info('Cargando predicciones para estudiante ${widget.estudianteId}', tag: 'PREDICCION_WIDGET');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prediccionProvider = Provider.of<PrediccionCompletaProvider>(context, listen: false);
      
      // Cargar predicciones y estadísticas en paralelo
      final results = await Future.wait([
        prediccionProvider.getPrediccionesCompletas(
          estudianteId: widget.estudianteId,
          materiaId: widget.materiaId,
          gestionId: widget.gestionId,
        ),
        prediccionProvider.getEstadisticasPredicciones(
          estudianteId: widget.estudianteId,
          materiaId: widget.materiaId,
          gestionId: widget.gestionId,
        ),
      ]);

      if (mounted) {
        setState(() {
          _predicciones = results[0] as List<PrediccionCompleta>;
          _estadisticas = results[1] as Map<String, dynamic>;
        });

        DebugLogger.info('Predicciones cargadas: ${_predicciones?.length ?? 0}', tag: 'PREDICCION_WIDGET');
      }
    } catch (e) {
      DebugLogger.error('Error cargando predicciones', tag: 'PREDICCION_WIDGET', error: e);
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Predicciones de Rendimiento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contenido principal
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_predicciones == null || _predicciones!.isEmpty)
            _buildEmptyState()
          else
            _buildPrediccionesContent(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Analizando datos del estudiante...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            'Error al cargar predicciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarPredicciones,
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

  Widget _buildEmptyState() {
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
            Icons.timeline_rounded,
            color: Colors.orange.shade700,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin predicciones disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay suficientes datos para generar predicciones de rendimiento.',
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

  Widget _buildPrediccionesContent() {
    final ultimaPrediccion = _predicciones!.last;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen destacado
        _buildResumenPrincipal(ultimaPrediccion),
        
        // Estadísticas generales
        if (_estadisticas != null) ...[
          const SizedBox(height: 16),
          _buildEstadisticasGenerales(),
        ],
        
        // Detalles expandibles
        if (_isExpanded) ...[
          const SizedBox(height: 20),
          _buildDetallesCompletos(),
        ],
        
        // Botón para ver más/menos
        const SizedBox(height: 12),
        _buildToggleButton(),
      ],
    );
  }

  Widget _buildResumenPrincipal(PrediccionCompleta ultimaPrediccion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ultimaPrediccion.colorClasificacion.withOpacity(0.15),
            ultimaPrediccion.colorClasificacion.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ultimaPrediccion.colorClasificacion.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ultimaPrediccion.colorClasificacion,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ultimaPrediccion.colorClasificacion.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ultimaPrediccion.iconoClasificacion,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  ultimaPrediccion.resultadoNumerico.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predicción Actual: ${ultimaPrediccion.clasificacion}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ultimaPrediccion.colorClasificacion,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ultimaPrediccion.descripcionPrediccion,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Período: ${ultimaPrediccion.periodoNombre}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasGenerales() {
    if (_estadisticas == null) return const SizedBox.shrink();

    final tendencia = _estadisticas!['tendencia'] ?? 'Sin datos';
    final promedioResultado = (_estadisticas!['promedio_resultado'] ?? 0.0) as double;
    final totalPredicciones = _estadisticas!['total_predicciones'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis de Tendencia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricaRapida('Tendencia', tendencia, _getIconForTendencia(tendencia)),
              _buildMetricaRapida('Promedio', promedioResultado.toStringAsFixed(1), Icons.analytics),
              _buildMetricaRapida('Períodos', totalPredicciones.toString(), Icons.timeline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaRapida(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDetallesCompletos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de Predicciones',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Lista de todas las predicciones
        ...(_predicciones ?? []).map((prediccion) => 
          _buildPrediccionItem(prediccion)
        ).toList(),
        
        // Recomendaciones
        const SizedBox(height: 16),
        _buildRecomendaciones(),
      ],
    );
  }

  Widget _buildPrediccionItem(PrediccionCompleta prediccion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: prediccion.colorClasificacion.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        color: prediccion.colorClasificacion.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: prediccion.colorClasificacion,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      prediccion.iconoClasificacion,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      prediccion.clasificacion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prediccion.periodoNombre,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                prediccion.resultadoNumerico.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: prediccion.colorClasificacion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricaDetalle('Notas', prediccion.promedioNotas),
              ),
              Expanded(
                child: _buildMetricaDetalle('Asistencia', prediccion.porcentajeAsistencia),
              ),
              Expanded(
                child: _buildMetricaDetalle('Participación', prediccion.promedioParticipacion),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaDetalle(String label, double value) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getColorForValue(value),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRecomendaciones() {
    if (_predicciones == null || _predicciones!.isEmpty) return const SizedBox.shrink();

    final ultimaPrediccion = _predicciones!.last;
    final recomendaciones = ultimaPrediccion.recomendaciones;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recomendaciones.map((recomendacion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recomendacion,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          // Información adicional
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Área de fortaleza: ${ultimaPrediccion.areaFortaleza}\nÁrea a mejorar: ${ultimaPrediccion.areaMejora}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        icon: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Theme.of(context).primaryColor,
        ),
        label: Text(
          _isExpanded ? 'Ver menos' : 'Ver detalles completos',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  IconData _getIconForTendencia(String tendencia) {
    switch (tendencia.toLowerCase()) {
      case 'mejorando':
        return Icons.trending_up;
      case 'empeorando':
        return Icons.trending_down;
      case 'estable':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForValue(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.amber;
    return Colors.red;
  }
}