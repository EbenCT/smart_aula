// lib/screens/notificaciones/lista_notificaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_api_service.dart';
import '../../utils/debug_logger.dart';

class ListaNotificacionesScreen extends StatefulWidget {
  static const routeName = '/notificaciones';

  const ListaNotificacionesScreen({Key? key}) : super(key: key);

  @override
  _ListaNotificacionesScreenState createState() => _ListaNotificacionesScreenState();
}

class _ListaNotificacionesScreenState extends State<ListaNotificacionesScreen> {
  List<Map<String, dynamic>> _notificaciones = [];
  bool _isLoading = false;
  String? _errorMessage;
  late NotificationApiService _notificationService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _notificationService = NotificationApiService(authService);
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DebugLogger.info('Cargando notificaciones', tag: 'NOTIFICACIONES');
      final notificaciones = await _notificationService.obtenerMisNotificaciones();
      
      setState(() {
        _notificaciones = notificaciones;
        _isLoading = false;
      });
      
      DebugLogger.info('Notificaciones cargadas: ${notificaciones.length}', tag: 'NOTIFICACIONES');
    } catch (e) {
      DebugLogger.error('Error cargando notificaciones: $e', tag: 'NOTIFICACIONES');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarComoLeida(Map<String, dynamic> notificacion) async {
    if (notificacion['leida'] == true) return;

    try {
      await _notificationService.marcarNotificacionComoLeida(notificacion['id']);
      
      setState(() {
        notificacion['leida'] = true;
      });
      
      DebugLogger.info('Notificación ${notificacion['id']} marcada como leída');
    } catch (e) {
      DebugLogger.error('Error marcando notificación como leída: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar como leída: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

String _formatearFecha(dynamic fechaStr) {
  if (fechaStr == null) return 'Fecha desconocida';
  
  try {
    DateTime fecha;
    
    // Si es un string, parsearlo
    if (fechaStr is String) {
      fecha = DateTime.parse(fechaStr);
    } 
    // Si ya es DateTime, usarlo directamente
    else if (fechaStr is DateTime) {
      fecha = fechaStr;
    } 
    // Si no es ninguno de los anteriores, retornar error
    else {
      return 'Formato de fecha inválido';
    }
    
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inDays > 0) {
      return '${diferencia.inDays} día${diferencia.inDays == 1 ? '' : 's'} atrás';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} hora${diferencia.inHours == 1 ? '' : 's'} atrás';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes} minuto${diferencia.inMinutes == 1 ? '' : 's'} atrás';
    } else {
      return 'Hace un momento';
    }
  } catch (e) {
    // Si el parsing falla, intentar mostrar el valor original
    return fechaStr.toString();
  }
}
  Color _getColorForTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_outlined;
      case 'error':
        return Icons.error_outline;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarNotificaciones,
            tooltip: 'Actualizar',
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
            Text('Cargando notificaciones...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargarNotificaciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_notificaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes notificaciones',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las notificaciones aparecerán aquí cuando las recibas',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _notificaciones.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notificacion = _notificaciones[index];
          final isLeida = notificacion['leida'] == true;
          
          return Card(
            elevation: isLeida ? 1 : 3,
            color: isLeida 
                ? Theme.of(context).cardColor 
                : Theme.of(context).cardColor.withAlpha(255),
            child: InkWell(
              onTap: () => _marcarComoLeida(notificacion),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono basado en el tipo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getColorForTipo(notificacion['tipo']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForTipo(notificacion['tipo']),
                        color: _getColorForTipo(notificacion['tipo']),
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Contenido de la notificación
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título y estado
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notificacion['titulo'] ?? 'Sin título',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isLeida ? FontWeight.normal : FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                              ),
                              if (!isLeida)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Mensaje
                          Text(
                            notificacion['mensaje'] ?? 'Sin mensaje',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Fecha y tipo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatearFecha(notificacion['created_at']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                ),
                              ),
                              if (notificacion['tipo'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getColorForTipo(notificacion['tipo']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    notificacion['tipo'].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getColorForTipo(notificacion['tipo']),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}