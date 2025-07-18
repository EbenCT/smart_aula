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
        "duracion_minutos": 60,
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
      ).timeout(const Duration(seconds: 30));

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
    String? estado = 'activa',
  }) async {
    try {
      String endpoint = '/asistencia/sesiones/mis-sesiones?limite=50';
      
      if (cursoId != null) {
        endpoint += '&curso_id=$cursoId';
      }
      if (materiaId != null) {
        endpoint += '&materia_id=$materiaId';
      }
      if (estado != null) {
        endpoint += '&estado=$estado';
      }

      final url = '${AppConstants.apiBaseUrl}$endpoint';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['data'] ?? []);
      } else {
        DebugLogger.error('Error al obtener sesiones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      DebugLogger.error('Error al obtener sesiones: $e');
      return [];
    }
  }
}