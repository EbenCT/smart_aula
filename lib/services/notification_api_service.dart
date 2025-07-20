// lib/services/notification_api_service.dart
import './base_api_service.dart';
import './auth_service.dart';
import '../utils/debug_logger.dart';

class NotificationApiService extends BaseApiService {
  NotificationApiService(AuthService authService) : super(authService);

  // Obtener notificaciones del usuario actual
  Future<List<Map<String, dynamic>>> obtenerMisNotificaciones({
    int limit = 50,
    bool soloNoLeidas = false,
  }) async {
    try {
      DebugLogger.info('Obteniendo notificaciones - Límite: $limit, Solo no leídas: $soloNoLeidas');
      
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'solo_no_leidas': soloNoLeidas.toString(),
      };
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final endpoint = '/notificaciones/mis-notificaciones?$queryString';
      final result = await get(endpoint);
      
      // El endpoint devuelve directamente la lista de notificaciones
      if (result is List) {
        return List<Map<String, dynamic>>.from(result);
      }
      
      DebugLogger.warning('Respuesta inesperada del servidor: $result');
      return [];
      
    } catch (e) {
      DebugLogger.error('Error obteniendo notificaciones: $e');
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  // Marcar notificación como leída
  Future<Map<String, dynamic>> marcarNotificacionComoLeida(int notificationId) async {
    try {
      DebugLogger.info('Marcando notificación $notificationId como leída');
      
      final endpoint = '/notificaciones/$notificationId/marcar-leida';
      final result = await put(endpoint, {});
      
      DebugLogger.info('Notificación $notificationId marcada como leída exitosamente');
      return result;
      
    } catch (e) {
      DebugLogger.error('Error marcando notificación como leída: $e');
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  // Contar notificaciones no leídas
  Future<int> contarNotificacionesNoLeidas() async {
    try {
      DebugLogger.info('Contando notificaciones no leídas');
      
      final result = await get('/notificaciones/count-no-leidas');
      
      // Asumiendo que el endpoint devuelve algo como {"count": 5}
      if (result is Map<String, dynamic> && result.containsKey('count')) {
        return result['count'] as int;
      }
      
      return 0;
      
    } catch (e) {
      DebugLogger.error('Error contando notificaciones no leídas: $e');
      return 0;
    }
  }
}