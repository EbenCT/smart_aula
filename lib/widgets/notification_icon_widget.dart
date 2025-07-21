// lib/widgets/notification_icon_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_api_service.dart';
import '../screens/notificaciones/lista_notificaciones_screen.dart';
import '../utils/debug_logger.dart';

class NotificationIconWidget extends StatefulWidget {
  const NotificationIconWidget({Key? key}) : super(key: key);

  @override
  _NotificationIconWidgetState createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  int _notificacionesNoLeidas = 0;
  bool _isLoading = false;
  late NotificationApiService _notificationService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _notificationService = NotificationApiService(authService);
    _cargarConteoNotificaciones();
  }

  Future<void> _cargarConteoNotificaciones() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _notificationService.contarNotificacionesNoLeidas();
      if (mounted) {
        setState(() {
          _notificacionesNoLeidas = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      DebugLogger.error('Error cargando conteo de notificaciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNotificationTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ListaNotificacionesScreen(),
      ),
    ).then((_) {
      // Recargar conteo al regresar de la pantalla de notificaciones
      _cargarConteoNotificaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _onNotificationTap,
          tooltip: 'Notificaciones',
        ),
        if (_notificacionesNoLeidas > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _notificacionesNoLeidas > 99 ? '99+' : _notificacionesNoLeidas.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}