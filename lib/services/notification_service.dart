import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/debug_logger.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Timer? _notificationTimer;
  bool _isServiceRunning = false;
  ApiService? _apiService;
  
  // Configuración inicial
  Future<void> initialize(ApiService apiService) async {
    _apiService = apiService;
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    DebugLogger.info('NotificationService inicializado');
  }
  
  // Solicitar permisos
  Future<bool> requestPermissions() async {
    try {
      // Permisos para Android
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (status != PermissionStatus.granted) {
          DebugLogger.warning('Permisos de notificación denegados');
          return false;
        }
      }
      
      // Permisos para iOS
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      DebugLogger.info('Permisos de notificación: ${result ?? true}');
      return result ?? true;
    } catch (e) {
      DebugLogger.error('Error solicitando permisos: $e');
      return false;
    }
  }
  
  // Iniciar el servicio de verificación
  Future<void> startService() async {
    if (_isServiceRunning || _apiService == null) return;
    
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      DebugLogger.warning('No se pueden iniciar notificaciones sin permisos');
      return;
    }
    
    _isServiceRunning = true;
    DebugLogger.info('Servicio de notificaciones iniciado');
    
    // Verificar inmediatamente
    _checkNotifications();
    
    // Programar verificaciones cada 30 segundos
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkNotifications(),
    );
  }
  
  // Detener el servicio
  void stopService() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _isServiceRunning = false;
    DebugLogger.info('Servicio de notificaciones detenido');
  }
  
  // Verificar notificaciones en el backend
  Future<void> _checkNotifications() async {
    if (!_isServiceRunning || _apiService == null) return;
    
    try {
      DebugLogger.info('Verificando notificaciones...');
      
      final notificaciones = await _apiService!.obtenerMisNotificaciones(
        limit: 50,
        soloNoLeidas: true,
      );
      
      if (notificaciones.isNotEmpty) {
        // Mostrar solo la primera notificación no leída
        final notificacion = notificaciones.first;
        await _showLocalNotification(notificacion);
        await _markAsRead(notificacion['id']);
        
        DebugLogger.info(
          'Notificación mostrada: ${notificacion['titulo']}'
        );
      }
    } catch (e) {
      DebugLogger.error('Error verificando notificaciones: $e');
    }
  }
  
  // Mostrar notificación local
  Future<void> _showLocalNotification(Map<String, dynamic> notificacion) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'academic_notifications',
      'Notificaciones Académicas',
      channelDescription: 'Notificaciones de calificaciones y avisos escolares',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      notificacion['id'] ?? 0,
      notificacion['titulo'] ?? 'Notificación',
      notificacion['mensaje'] ?? '',
      platformChannelSpecifics,
    );
  }
  
  // Marcar notificación como leída
  Future<void> _markAsRead(int notificationId) async {
    try {
      await _apiService!.marcarNotificacionComoLeida(notificationId);
      DebugLogger.info('Notificación $notificationId marcada como leída');
    } catch (e) {
      DebugLogger.error('Error marcando notificación como leída: $e');
    }
  }
  
  // Getters para el estado del servicio
  bool get isRunning => _isServiceRunning;
}