import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/estudiante.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/hijo_card_widget.dart';
import '../../widgets/empty_state_widget.dart';

class PadreHomeScreen extends StatefulWidget {
  static const routeName = '/padre-home';

  const PadreHomeScreen({Key? key}) : super(key: key);

  @override
  _PadreHomeScreenState createState() => _PadreHomeScreenState();
}

class _PadreHomeScreenState extends State<PadreHomeScreen> {
  List<Estudiante>? _hijos;
  bool _isLoading = true;
  String? _errorMessage;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
  }

  void _initializeApiService() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _cargarHijos();
  }

  Future<void> _cargarHijos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hijos = await _apiService.getMisHijos();
      
      if (mounted) {
        setState(() {
          _hijos = hijos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refrescarHijos() async {
    try {
      final hijos = await _apiService.refrescarHijos();
      
      if (mounted) {
        setState(() {
          _hijos = hijos;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al refrescar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Hijos'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refrescarHijos,
                tooltip: 'Refrescar',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, authService),
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: Column(
              children: [
                // Header con información del padre
                _buildHeaderInfo(authService),
                
                // Lista de hijos
                Expanded(
                  child: _buildHijosContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfo(AuthService authService) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom,
              size: 32,
              color: Theme.of(context).primaryColor,
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
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                if (authService.correo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authService.correo!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _hijos!.length,
        itemBuilder: (context, index) {
          final hijo = _hijos![index];
          return HijoCardWidget(
            hijo: hijo,
            onTap: () => _mostrarDetalleHijo(hijo),
          );
        },
      ),
    );
  }

  void _mostrarDetalleHijo(Estudiante hijo) {
    // Por ahora mostrar un diálogo con la información del hijo
    // En el futuro se puede navegar a una pantalla de detalle
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hijo.nombreCompleto),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Fecha de Nacimiento', 
                '${hijo.fechaNacimiento.day}/${hijo.fechaNacimiento.month}/${hijo.fechaNacimiento.year}'),
            _buildInfoRow('Género', hijo.genero),
            _buildInfoRow('Correo', hijo.email),
            if (hijo.direccionCasa.isNotEmpty)
              _buildInfoRow('Dirección', hijo.direccionCasa),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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
}