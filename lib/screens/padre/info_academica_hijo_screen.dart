// lib/screens/padre/info_academica_hijo_screen.dart
import 'package:flutter/material.dart';
import '../../models/estudiante.dart';
import '../../models/info_academica_completa.dart';
import '../../services/padre_api_service.dart';
import '../../services/auth_service.dart';
import '../../screens/estudiantes/detalle_materia_estudiante_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/card_container_widget.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/debug_logger.dart';
import 'package:provider/provider.dart';

class InfoAcademicaHijoScreen extends StatefulWidget {
  final Estudiante hijo;

  const InfoAcademicaHijoScreen({
    Key? key,
    required this.hijo,
  }) : super(key: key);

  @override
  _InfoAcademicaHijoScreenState createState() => _InfoAcademicaHijoScreenState();
}

class _InfoAcademicaHijoScreenState extends State<InfoAcademicaHijoScreen> {
  InfoAcademicaCompleta? _infoAcademica;
  bool _isLoading = false;
  String? _errorMessage;
  late PadreApiService _padreApiService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _padreApiService = PadreApiService(authService);
    _cargarInfoAcademica();
  }

  Future<void> _cargarInfoAcademica() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DebugLogger.info('Cargando información académica del hijo ID: ${widget.hijo.id}', tag: 'INFO_ACADEMICA');
      final info = await _padreApiService.getInfoAcademicaCompleta(widget.hijo.id);
      
      setState(() {
        _infoAcademica = info;
        _isLoading = false;
      });
      
      DebugLogger.info('Información académica cargada exitosamente', tag: 'INFO_ACADEMICA');
    } catch (e) {
      DebugLogger.error('Error cargando información académica: $e', tag: 'INFO_ACADEMICA');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refrescarInfo() async {
    await _cargarInfoAcademica();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hijo.nombreCompleto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Información Académica',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescarInfo,
            tooltip: 'Actualizar información',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando información académica...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar la información',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarInfoAcademica,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_infoAcademica == null) {
      return EmptyStateWidget(
        icon: Icons.school_outlined,
        title: 'No hay información disponible',
        subtitle: 'No se encontró información académica para este estudiante',
        action: ElevatedButton.icon(
          onPressed: _cargarInfoAcademica,
          icon: const Icon(Icons.refresh),
          label: const Text('Refrescar'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescarInfo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con información del estudiante
              _buildHeaderCard(),
              
              const SizedBox(height: 16),
              
              // Información del curso
              _buildCursoCard(),
              
              const SizedBox(height: 16),
              
              // Estadísticas
              _buildEstadisticasCards(),
              
              const SizedBox(height: 24),
              
              // Lista de materias
              _buildMateriasSection(),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 4 : 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          children: [
            AvatarWidget(
              nombre: _infoAcademica!.estudiante.nombre,
              apellido: _infoAcademica!.estudiante.apellido,
              radius: 40,
              backgroundColor: Colors.white,
              textColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _infoAcademica!.estudiante.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _infoAcademica!.estudiante.correo ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Gestión ${_infoAcademica!.gestion.anio}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursoCard() {
    return CardContainerWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título e ícono
          Row(
            children: [
              Icon(
                Icons.class_,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Información del Curso',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contenido
          _buildInfoRow('Curso', _infoAcademica!.curso.nombre),
          _buildInfoRow('Nivel', _infoAcademica!.curso.nivel),
          _buildInfoRow('Paralelo', _infoAcademica!.curso.paralelo),
          _buildInfoRow('Turno', _infoAcademica!.curso.turno),
          _buildInfoRow('Inscripción', _infoAcademica!.inscripcion.descripcion),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCards() {
    final estadisticas = _infoAcademica!.estadisticas;
    
    return Row(
      children: [
        Expanded(
          child: _buildEstadisticaCard(
            'Total Materias',
            estadisticas.totalMaterias.toString(),
            Icons.book,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEstadisticaCard(
            'Con Docente',
            estadisticas.materiasConDocente.toString(),
            Icons.person,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEstadisticaCard(
            'Docentes',
            estadisticas.totalDocentesUnicos.toString(),
            Icons.group,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticaCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriasSection() {
    if (_infoAcademica!.materias.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.book_outlined,
        title: 'No hay materias',
        subtitle: 'Este estudiante no tiene materias asignadas',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materias (${_infoAcademica!.materias.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: _infoAcademica!.materias.map((materiaConDocente) {
              final materia = materiaConDocente.materia;
              final docente = materiaConDocente.docente;
              final tieneDocente = docente != null;

              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tieneDocente ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.book,
                    color: tieneDocente ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(
                  materia.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (materia.descripcion != null) ...[
                      Text(materia.descripcion!),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      tieneDocente 
                          ? 'Prof. ${docente.nombre} ${docente.apellido}'
                          : 'Sin docente asignado',
                      style: TextStyle(
                        color: tieneDocente 
                            ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: tieneDocente ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _navigateToMateriaDetail(materia.id, materia.nombre),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _navigateToMateriaDetail(int materiaId, String materiaNombre) {
    // Navegar a la pantalla de detalle de materia del estudiante
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleMateriasEstudianteScreen(
          estudianteId: _infoAcademica!.estudiante.id.toString(),
          materiaId: materiaId,
          cursoId: _infoAcademica!.curso.id,
          materiaNombre: materiaNombre,
          cursoNombre: _infoAcademica!.curso.nombre,
        ),
      ),
    );
  }
}