// lib/screens/estudiantes/estudiante_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/biometric_service.dart';
import '../../widgets/notification_icon_widget.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/resumen_card.dart';
import '../../models/dashboard_estudiante.dart';
import '../../screens/estudiantes/detalle_materia_estudiante_screen.dart';
import '../../utils/debug_logger.dart';

class EstudianteHomeScreen extends StatefulWidget {
  static const routeName = '/estudiante-home';

  const EstudianteHomeScreen({Key? key}) : super(key: key);

  @override
  _EstudianteHomeScreenState createState() => _EstudianteHomeScreenState();
}

class _EstudianteHomeScreenState extends State<EstudianteHomeScreen> {
  DashboardEstudiante? _dashboard;
  bool _isLoading = false;
  String? _error;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getDashboardEstudiante();
      if (response['success'] == true) {
        setState(() {
          _dashboard = DashboardEstudiante.fromJson(response);
        });
      } else {
        setState(() {
          _error = response['mensaje'] ?? 'Error al cargar datos';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              authService.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Portal Estudiante'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              const ThemeToggleButton(),
              const NotificationIconWidget(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _cargarDashboard,
                tooltip: 'Actualizar',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, authService),
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboard == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando dashboard...'),
          ],
        ),
      );
    }

    if (_error != null && _dashboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargarDashboard,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_dashboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 72,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay información disponible',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _cargarDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeaderCard(),

              const SizedBox(height: 16),

              // Estadísticas principales
              _buildMainStatsCards(),

              const SizedBox(height: 16),

              // Estadísticas detalladas
              _buildDetailedStatsCards(),

              const SizedBox(height: 24),

              // Lista de materias
              _buildMateriasSection(isDarkMode),

              const SizedBox(height: 24),

              // Botón para marcar asistencia
              _buildMarcarAsistenciaButton(),

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dashboard!.nombreEstudiante,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    _dashboard!.nombreCurso,
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
    );
  }

  Widget _buildMainStatsCards() {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: 'Materias',
            valor: _dashboard!.totalMaterias.toString(),
            icono: Icons.subject,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Docentes',
            valor: _dashboard!.totalDocentes.toString(),
            icono: Icons.people,
            color: _getColorForDocentes(_dashboard!.totalDocentes),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStatsCards() {
    return Row(
      children: [
        Expanded(
          child: ResumenCard(
            titulo: 'Con Docente',
            valor: _dashboard!.materiasConDocente.toString(),
            icono: Icons.check_circle,
            color: _getColorForMaterias(_dashboard!.materiasConDocente, _dashboard!.totalMaterias),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ResumenCard(
            titulo: 'Completitud',
            valor: '${_dashboard!.porcentajeCompleto.toStringAsFixed(1)}%',
            icono: Icons.pie_chart,
            color: _getColorForPorcentaje(_dashboard!.porcentajeCompleto),
          ),
        ),
      ],
    );
  }

  Widget _buildMateriasSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Materias',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: isDarkMode ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: _dashboard!.materias.map<Widget>((materia) {
              final materiaData = materia['materia'];
              final docenteData = materia['docente'];
              final tieneDocente = docenteData != null;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    tieneDocente ? Icons.school : Icons.warning,
                    color: tieneDocente ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  title: Text(
                    materiaData['nombre'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    tieneDocente 
                        ? 'Prof. ${docenteData['nombre']} ${docenteData['apellido']}'
                        : 'Sin docente asignado',
                    style: TextStyle(
                      color: tieneDocente 
                          ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                          : Colors.orange,
                    ),
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
                  onTap: () => _navigateToMateriaDetail(context, materiaData['id']),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Construir el botón para marcar asistencia
  Widget _buildMarcarAsistenciaButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _mostrarSesionesActivas,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg, size: 24),
            const SizedBox(width: 12),
            Text(
              'Marcar Asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar las sesiones activas CON AUTENTICACIÓN BIOMÉTRICA
  Future<void> _mostrarSesionesActivas() async {
    try {
      // PASO 1: Autenticación biométrica
      DebugLogger.info('Iniciando autenticación biométrica para marcar asistencia');
      
      final biometricResult = await BiometricService.instance.authenticate(
        reason: 'Verificar tu identidad para marcar asistencia',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      // Si la autenticación no fue exitosa, mostrar error y salir
      if (!biometricResult.isSuccess) {
        _mostrarErrorBiometrico(biometricResult);
        return;
      }

      // PASO 2: Si la autenticación fue exitosa, continuar con el flujo normal
      DebugLogger.info('Autenticación biométrica exitosa, cargando sesiones...');
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Cargando sesiones activas...'),
                ],
              ),
            ),
          ),
        ),
      );

      final sesionesActivas = await _apiService.estudiantes.getSesionesActivas();
      
      // Cerrar indicador de carga
      Navigator.of(context).pop();
      
      if (sesionesActivas.isEmpty) {
        // No hay sesiones activas
        _mostrarMensajeNoSesiones();
      } else {
        // Mostrar sesiones activas
        _mostrarModalSesionesActivas(sesionesActivas);
      }
    } catch (e) {
      // Cerrar cualquier diálogo abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Mostrar error
      _mostrarErrorSesiones(e.toString());
    }
  }

  // Mostrar error biométrico
  void _mostrarErrorBiometrico(BiometricResult result) {
    Color iconColor = Colors.orange;
    IconData iconData = Icons.fingerprint;
    String title = 'Autenticación Requerida';

    // Personalizar según el tipo de error
    switch (result.type) {
      case BiometricResultType.cancelled:
        iconColor = Colors.blue;
        iconData = Icons.cancel_outlined;
        title = 'Autenticación Cancelada';
        break;
      case BiometricResultType.notAvailable:
        iconColor = Colors.grey;
        iconData = Icons.warning_outlined;
        title = 'Biometría No Disponible';
        break;
      case BiometricResultType.notEnrolled:
        iconColor = Colors.orange;
        iconData = Icons.fingerprint_outlined;
        title = 'Configurar Huella Digital';
        break;
      case BiometricResultType.lockedOut:
      case BiometricResultType.permanentlyLockedOut:
        iconColor = Colors.red;
        iconData = Icons.lock_outlined;
        title = 'Biometría Bloqueada';
        break;
      case BiometricResultType.error:
        iconColor = Colors.red;
        iconData = Icons.error_outline;
        title = 'Error de Autenticación';
        break;
      default:
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(iconData, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message ?? 'Error desconocido'),
            if (result.type == BiometricResultType.notEnrolled) ...[
              const SizedBox(height: 16),
              Text(
                'Para usar esta función, configura tu huella digital en los ajustes del dispositivo.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Mostrar mensaje cuando no hay sesiones activas
  void _mostrarMensajeNoSesiones() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Sin sesiones activas'),
          ],
        ),
        content: Text('No hay sesiones de asistencia activas en este momento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Mostrar error al cargar sesiones
  void _mostrarErrorSesiones(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text('Error al cargar las sesiones activas: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Mostrar modal con las sesiones activas
  void _mostrarModalSesionesActivas(List<Map<String, dynamic>> sesiones) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del modal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.how_to_reg, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sesiones de Asistencia Activas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Lista de sesiones
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: sesiones.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sesion = sesiones[index];
                    return _buildSesionCard(sesion);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construir card para cada sesión
  Widget _buildSesionCard(Map<String, dynamic> sesion) {
    final materia = sesion['materia'] ?? {};
    final docente = sesion['docente'] ?? {};
    final miAsistencia = sesion['mi_asistencia'];
    
    // CORREGIDO: Verificar si ya marcó asistencia correctamente
    // El estudiante ha marcado asistencia si existe mi_asistencia Y fecha_marcado no es null
    final yaMarcoAsistencia = miAsistencia != null && 
        miAsistencia['fecha_marcado'] != null;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sesión
            Text(
              sesion['titulo'] ?? 'Sesión de Asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Información de la materia
            Row(
              children: [
                Icon(Icons.book, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Materia: ${materia['nombre'] ?? 'No especificada'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Información del docente
            Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Docente: ${docente['nombre'] ?? ''} ${docente['apellido'] ?? ''}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estado de asistencia y botón
            if (yaMarcoAsistencia) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Asistencia ya marcada',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _marcarAsistencia(sesion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_reg, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Marcar Asistencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Marcar asistencia - IMPLEMENTACIÓN COMPLETA
  Future<void> _marcarAsistencia(Map<String, dynamic> sesion) async {
    try {
      // Cerrar el modal actual
      Navigator.of(context).pop();
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Obteniendo ubicación...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Obtener ubicación del usuario
      final location = await LocationService.instance.getCurrentLocation();
      
      if (location == null) {
        Navigator.of(context).pop(); // Cerrar indicador de carga
        throw Exception('No se pudo obtener la ubicación. Verifique los permisos.');
      }

      // Actualizar mensaje de carga
      Navigator.of(context).pop(); // Cerrar indicador anterior
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Marcando asistencia...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Marcar asistencia usando el API
      final resultado = await _apiService.estudiantes.marcarAsistencia(
        sesion['id'],
        location['latitude']!,
        location['longitude']!,
        observaciones: 'presente',
      );

      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Mostrar resultado exitoso
      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ ${resultado['message'] ?? 'Asistencia marcada exitosamente'}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (resultado['es_tardanza'] == true)
                  Text(
                    'Nota: Marcada como tardanza',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade100),
                  ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(resultado['message'] ?? 'Error desconocido al marcar asistencia');
      }

    } catch (e) {
      // Cerrar cualquier diálogo abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Mostrar error
      DebugLogger.error('Error al marcar asistencia: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Métodos de color
  Color _getColorForDocentes(int totalDocentes) {
    if (totalDocentes >= 4) return Colors.green;
    if (totalDocentes >= 2) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForMaterias(int materiasConDocente, int totalMaterias) {
    if (materiasConDocente == totalMaterias) return Colors.green;
    if (materiasConDocente >= totalMaterias * 0.7) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForPorcentaje(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 70) return Colors.orange;
    return Colors.red;
  }

  void _navigateToMateriaDetail(BuildContext context, int materiaId) {
    if (_dashboard == null) return;

    // Encontrar la materia seleccionada
    final materiaData = _dashboard!.materias.firstWhere(
      (m) => m['materia']['id'] == materiaId,
    );

    final materia = materiaData['materia'];

    // Navegar a la nueva pantalla específica para estudiantes
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleMateriasEstudianteScreen(
          estudianteId: _dashboard!.estudiante['id'].toString(),
          materiaId: materia['id'],
          cursoId: _dashboard!.curso['id'],
          materiaNombre: materia['nombre'],
          cursoNombre: _dashboard!.curso['nombre'],
        ),
      ),
    );
  }
}