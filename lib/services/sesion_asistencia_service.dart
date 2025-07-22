// lib/services/sesion_asistencia_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../services/auth_service.dart';
import '../utils/debug_logger.dart';

class SesionAsistenciaService {
  final AuthService _authService;

  SesionAsistenciaService(this._authService);

  // Obtener encabezados con autenticación
  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  /// Crea una sesión automática de asistencia
  Future<Map<String, dynamic>?> crearSesionAutomatica({
    required int cursoId,
    required int materiaId,
    required double latitud,
    required double longitud,
    String titulo = "Asistencia",
  }) async {
    try {
      final requestData = {
        "titulo": titulo,
        "descripcion": "Sesión automática de asistencia",
        "curso_id": cursoId,
        "materia_id": materiaId,
        "periodo_id": null, // Se detecta automáticamente
        "duracion_minutos": 10,
        "radio_permitido_metros": 100,
        "permite_asistencia_tardia": true,
        "minutos_tolerancia": 15,
        "latitud_docente": latitud,
        "longitud_docente": longitud,
        "direccion_referencia": "Aula de clases",
        "fecha_inicio": DateTime.now().toIso8601String(),
      };

      DebugLogger.info('Creando sesión automática con datos: $requestData');

      final url = '${AppConstants.apiBaseUrl}/asistencia/sesiones';
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 60));

      DebugLogger.info('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        DebugLogger.info('Sesión creada exitosamente: ${responseData['message']}');
        return responseData;
      } else {
        DebugLogger.error('Error al crear sesión: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Excepción al crear sesión: $e');
      rethrow;
    }
  }

  /// Obtiene las sesiones del docente
  Future<List<Map<String, dynamic>>> obtenerMisSesiones({
    int? cursoId,
    int? materiaId,
    String? estado,
    int limite = 50,
  }) async {
    try {
      var url = '${AppConstants.apiBaseUrl}/asistencia/sesiones/mis-sesiones?limite=$limite';
      
      if (estado != null) {
        url += '&estado=$estado';
      }
      if (cursoId != null) {
        url += '&curso_id=$cursoId';
      }
      if (materiaId != null) {
        url += '&materia_id=$materiaId';
      }

      DebugLogger.info('Obteniendo sesiones: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 60));

      DebugLogger.info('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        DebugLogger.info('Sesiones obtenidas exitosamente: ${responseData['total']} sesiones');
        return List<Map<String, dynamic>>.from(responseData['sesiones'] ?? []);
      } else {
        DebugLogger.error('Error al obtener sesiones: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Excepción al obtener sesiones: $e');
      rethrow;
    }
  }

  /// ✅ NUEVO: Obtener estadísticas de una sesión específica
  Future<Map<String, dynamic>> obtenerEstadisticasSesion(int sesionId) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/asistencia/sesiones/$sesionId/estadisticas';
      
      DebugLogger.info('Obteniendo estadísticas de sesión: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 60));

      DebugLogger.info('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        DebugLogger.info('Estadísticas obtenidas exitosamente');
        return responseData;
      } else {
        DebugLogger.error('Error al obtener estadísticas: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Excepción al obtener estadísticas: $e');
      rethrow;
    }
  }

  /// Obtener detalle completo de una sesión
  Future<Map<String, dynamic>?> obtenerDetalleSesion(int sesionId) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/asistencia/sesiones/$sesionId';
      
      DebugLogger.info('Obteniendo detalle de sesión: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 60));

      DebugLogger.info('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        DebugLogger.info('Detalle de sesión obtenido exitosamente');
        return responseData;
      } else {
        DebugLogger.error('Error al obtener detalle: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Excepción al obtener detalle: $e');
      rethrow;
    }
  }

  /// Actualizar configuración de una sesión
  Future<Map<String, dynamic>?> actualizarSesion(
    int sesionId,
    Map<String, dynamic> datos,
  ) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/asistencia/sesiones/$sesionId';
      
      DebugLogger.info('Actualizando sesión: $url con datos: $datos');
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(datos),
      ).timeout(const Duration(seconds: 60));

      DebugLogger.info('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        DebugLogger.info('Sesión actualizada exitosamente');
        return responseData;
      } else {
        DebugLogger.error('Error al actualizar sesión: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Excepción al actualizar sesión: $e');
      rethrow;
    }
  }

  /// Cerrar una sesión de asistencia
  Future<Map<String, dynamic>?> cerrarSesion(int sesionId) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/asistencia/sesiones/$sesionId/cerrar';
      
      DebugLogger.info('Cerrando sesión: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 60));

      DebugLogger.info('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        DebugLogger.info('Sesión cerrada exitosamente: ${responseData['message']}');
        return responseData;
      } else {
        DebugLogger.error('Error al cerrar sesión: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Excepción al cerrar sesión: $e');
      rethrow;
    }
  }

  /// Justificar ausencia de un estudiante
  Future<Map<String, dynamic>?> justificarAusencia(
    int sesionId,
    int estudianteId,
    String motivo,
    String? observaciones,
  ) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/asistencia/sesiones/$sesionId/estudiantes/$estudianteId/justificar';
      
      final requestData = {
        "motivo_justificacion": motivo,
        if (observaciones != null) "observaciones": observaciones,
      };

      DebugLogger.info('Justificando ausencia: $url con datos: $requestData');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 60));

      DebugLogger.info('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        DebugLogger.info('Ausencia justificada exitosamente');
        return responseData;
      } else {
        DebugLogger.error('Error al justificar ausencia: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Excepción al justificar ausencia: $e');
      rethrow;
    }
  }
}