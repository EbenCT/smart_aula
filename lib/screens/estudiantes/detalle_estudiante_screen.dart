// lib/screens/estudiantes/detalle_estudiante_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/curso_provider.dart';
import '../../providers/resumen_estudiante_provider.dart';
import '../../models/resumen_estudiante.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/card_container_widget.dart';

class DetalleEstudianteScreen extends StatefulWidget {
  final String estudianteId;

  const DetalleEstudianteScreen({
    Key? key,
    required this.estudianteId,
  }) : super(key: key);

  @override
  _DetalleEstudianteScreenState createState() => _DetalleEstudianteScreenState();
}

class _DetalleEstudianteScreenState extends State<DetalleEstudianteScreen> {
  ResumenEstudiante? _resumenEstudiante;
  bool _isLoadingResumen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarResumenEstudiante();
    });
  }

  Future<void> _cargarResumenEstudiante() async {
    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final resumenProvider = Provider.of<ResumenEstudianteProvider>(context, listen: false);
    
    if (!cursoProvider.tieneSeleccionCompleta) return;

    setState(() {
      _isLoadingResumen = true;
    });

    try {
      final resumen = await resumenProvider.getResumenEstudiante(
        estudianteId: int.parse(widget.estudianteId),
        materiaId: cursoProvider.materiaSeleccionada!.id,
        periodoId: 1, // Puedes ajustar esto según tu lógica
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _resumenEstudiante = resumen;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar resumen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingResumen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  estudiantesProvider.recargarEstudiantes();
                  _cargarResumenEstudiante();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Encabezado con información básica
                _buildHeaderSection(context, estudiante),
                
                // Información personal
                _buildInformacionPersonalCard(context, estudiante),
                
                // Información del tutor
                _buildInformacionTutorCard(context, estudiante),
                
                // Resumen académico (desde el endpoint)
                if (_resumenEstudiante != null)
                  _buildResumenAcademicoCard(context, _resumenEstudiante!),
                
                // Estado de carga del resumen
                if (_isLoadingResumen)
                  _buildLoadingResumenCard(context),
                
                // Información de asistencia detallada
                if (_resumenEstudiante?.tieneAsistencia == true)
                  _buildAsistenciaDetalladaCard(context, _resumenEstudiante!.asistencia!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, estudiante) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          AvatarWidget(
            nombre: estudiante.nombre,
            apellido: estudiante.apellido,
            radius: 50,
            backgroundColor: Colors.white,
            textColor: Theme.of(context).primaryColor,
            fontSize: 36,
          ),
          const SizedBox(height: 16),
          Text(
            estudiante.nombreCompleto,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            estudiante.codigo,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estudiante.email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionPersonalCard(BuildContext context, estudiante) {
    return CardContainerWidget(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            'Fecha de Nacimiento',
            DateFormat('dd/MM/yyyy').format(estudiante.fechaNacimiento),
            Icons.cake,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            context,
            'Género',
            estudiante.genero,
            Icons.person_outline,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            context,
            'Edad',
            '${_calcularEdad(estudiante.fechaNacimiento)} años',
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            context,
            'Dirección',
            estudiante.direccionCasa,
            Icons.home,
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
                Icons.family_restroom,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Información del Tutor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            'Nombre del Tutor',
            estudiante.nombreTutor,
            Icons.person,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            context,
            'Teléfono',
            estudiante.telefonoTutor,
            Icons.phone,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Llamar a ${estudiante.telefonoTutor}'),
                  action: SnackBarAction(
                    label: 'Cerrar',
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

  Widget _buildResumenAcademicoCard(BuildContext context, ResumenEstudiante resumen) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen Académico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Promedio general
          if (resumen.tieneEvaluaciones) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getColorForNota(resumen.promedioGeneral).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getColorForNota(resumen.promedioGeneral).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
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
                          fontSize: 18,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTextoRendimiento(resumen.promedioGeneral, false),
                          style: TextStyle(
                            color: _getColorForNota(resumen.promedioGeneral),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${resumen.evaluacionesAcademicas.length} tipos de evaluación',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Lista de evaluaciones por tipo
          ...resumen.evaluacionesAcademicas.map((evaluacion) => 
            _buildEvaluacionItem(context, evaluacion)
          ).toList(),
          
          if (!resumen.tieneEvaluaciones)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay evaluaciones registradas para este estudiante',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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

  Widget _buildEvaluacionItem(BuildContext context, TipoEvaluacion evaluacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getColorForNota(evaluacion.valorPrincipal),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  evaluacion.valorPrincipal.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evaluacion.nombre,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${evaluacion.total} evaluación(es)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                evaluacion.textoRendimiento,
                style: TextStyle(
                  color: _getColorForNota(evaluacion.valorPrincipal),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Mostrar detalle de evaluaciones si hay pocas
          if (evaluacion.detalle.length <= 3 && evaluacion.detalle.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...evaluacion.detalle.map((detalle) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${detalle.descripcion} - ${detalle.valor.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    _formatearFecha(detalle.fecha),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
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

  Widget _buildAsistenciaDetalladaCard(BuildContext context, TipoEvaluacion asistencia) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Registro de Asistencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Indicador de porcentaje
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getColorForAsistencia(asistencia.porcentaje ?? 0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getColorForAsistencia(asistencia.porcentaje ?? 0).withOpacity(0.3),
              ),
            ),
            child: Column(
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
                            'Porcentaje de Asistencia',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getTextoRendimiento(asistencia.porcentaje ?? 0, true),
                            style: TextStyle(
                              color: _getColorForAsistencia(asistencia.porcentaje ?? 0),
                              fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
          
          // Lista de registros de asistencia
          if (asistencia.detalle.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Registros Recientes:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...asistencia.detalle.take(5).map((detalle) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorForValorAsistencia(detalle.valor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detalle.descripcion,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatearFecha(detalle.fecha),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _getTextoEstadoAsistencia(detalle.valor),
                    style: TextStyle(
                      color: _getColorForValorAsistencia(detalle.valor),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildLoadingResumenCard(BuildContext context) {
    return CardContainerWidget(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando resumen académico...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
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
    Widget content = Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          ),
      ],
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
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
      return DateFormat('dd/MM/yyyy').format(dateTime);
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

  String _getTextoEstadoAsistencia(double valor) {
    if (valor >= 100) {
      return 'Presente';
    } else if (valor >= 75) {
      return 'Justificado';
    } else if (valor >= 50) {
      return 'Tardanza';
    } else {
      return 'Ausente';
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