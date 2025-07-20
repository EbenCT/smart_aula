// lib/utils/notification_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../utils/debug_logger.dart';

/// Helper class para manejar notificaciones desde cualquier parte de la app
class NotificationManager {
  
  /// Iniciar el servicio de notificaciones después del login
  static Future<void> startAfterLogin(BuildContext context) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.startService();
      DebugLogger.info('Notificaciones iniciadas después del login');
    } catch (e) {
      DebugLogger.error('Error iniciando notificaciones después del login: $e');
    }
  }

  /// Detener el servicio de notificaciones antes del logout
  static void stopBeforeLogout(BuildContext context) {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.stopService();
      DebugLogger.info('Notificaciones detenidas antes del logout');
    } catch (e) {
      DebugLogger.error('Error deteniendo notificaciones antes del logout: $e');
    }
  }

  /// Verificar el estado del servicio de notificaciones
  static bool isServiceRunning(BuildContext context) {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      return notificationService.isRunning;
    } catch (e) {
      DebugLogger.error('Error verificando estado de notificaciones: $e');
      return false;
    }
  }

  /// Reiniciar el servicio de notificaciones manualmente
  static Future<void> restart(BuildContext context) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.stopService();
      await Future.delayed(const Duration(seconds: 1));
      await notificationService.startService();
      DebugLogger.info('Servicio de notificaciones reiniciado');
    } catch (e) {
      DebugLogger.error('Error reiniciando notificaciones: $e');
    }
  }
}