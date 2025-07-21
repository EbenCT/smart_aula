// lib/screens/padre/padre_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/estudiante.dart';
import '../../services/padre_api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/debug_logger.dart';
import '../../widgets/notification_icon_widget.dart';
import './info_academica_hijo_screen.dart'; // Nueva importación

class PadreHomeScreen extends StatefulWidget {
  static const routeName = '/padre-home';

  const PadreHomeScreen({Key? key}) : super(key: key);

  @override
  _PadreHomeScreenState createState() => _PadreHomeScreenState();
}

class _PadreHomeScreenState extends State<PadreHomeScreen> 
    with AutomaticKeepAliveClientMixin {
  
  List<Estudiante>? _hijos;
  bool _isLoading = false;
  String? _errorMessage;
  late PadreApiService _padreApiService;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _padreApiService = PadreApiService(authService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarHijos();
    });
  }

  Future<void> _cargarHijos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DebugLogger.info('Cargando lista de hijos', tag: 'PADRE_HOME');
      final hijos = await _padreApiService.getMisHijos();
      
      setState(() {
        _hijos = hijos;
        _isLoading = false;
      });
      
      DebugLogger.info('Hijos cargados exitosamente: ${hijos.length}', tag: 'PADRE_HOME');
    } catch (e) {
      DebugLogger.error('Error cargando hijos: $e', tag: 'PADRE_HOME');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refrescarHijos() async {
    await _cargarHijos();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Mis Hijos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescarHijos,
            tooltip: 'Actualizar lista',
          ),
          const NotificationIconWidget(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información del padre
          _buildHeaderCard(),
          
          // Contenido principal
          Expanded(
            child: _buildHijosContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portal Padre/Madre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (authService.correo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authService.correo!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _hijos != null 
                      ? '${_hijos!.length} hijo${_hijos!.length == 1 ? '' : 's'} registrado${_hijos!.length == 1 ? '' : 's'}'
                      : 'Cargando información...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHijosContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando información de sus hijos...'),
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
                onPressed: _cargarHijos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_hijos == null || _hijos!.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'No hay hijos registrados',
        subtitle: 'No se encontraron estudiantes asociados a su cuenta',
        action: ElevatedButton.icon(
          onPressed: _cargarHijos,
          icon: const Icon(Icons.refresh),
          label: const Text('Refrescar'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescarHijos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: _hijos!.length,
        itemBuilder: (context, index) {
          final hijo = _hijos![index];
          return _buildHijoCard(hijo);
        },
      ),
    );
  }

  Widget _buildHijoCard(Estudiante hijo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToInfoAcademica(hijo), // Nueva navegación
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar del estudiante
              AvatarWidget(
                nombre: hijo.nombre,
                apellido: hijo.apellido,
                backgroundColor: Theme.of(context).primaryColor,
                radius: 30,
              ),
              const SizedBox(width: 16),
              
              // Información del estudiante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hijo.nombreCompleto,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hijo.codigo,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hijo.email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Indicador de navegación
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para navegar a la información académica del hijo
  void _navigateToInfoAcademica(Estudiante hijo) {
    DebugLogger.info('Navegando a información académica del hijo: ${hijo.nombreCompleto}', tag: 'PADRE_HOME');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InfoAcademicaHijoScreen(hijo: hijo),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<AuthService>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}