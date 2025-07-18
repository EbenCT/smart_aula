// lib/services/padre_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/estudiante.dart';
import '../models/info_academica_completa.dart';
import '../services/auth_service.dart';
import '../utils/debug_logger.dart';

class PadreApiService {
  final AuthService _authService;

  PadreApiService(this._authService);

  // Obtener encabezados con autenticación
  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Obtener lista de hijos del padre autenticado
  Future<List<Estudiante>> getMisHijos() async {
    try {
      final url = '${AppConstants.apiBaseUrl}/padres/mis-hijos';
      
      DebugLogger.info('Obteniendo hijos del padre desde: $url', tag: 'PADRE_API');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      DebugLogger.info('Respuesta obtenida: ${response.statusCode}', tag: 'PADRE_API');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        
        DebugLogger.info('Hijos encontrados: ${responseData.length}', tag: 'PADRE_API');
        
        final List<Estudiante> hijos = responseData.map((hijoJson) {
          // Agregar correo si no viene en la respuesta (para compatibilidad)
          if (!hijoJson.containsKey('correo') || hijoJson['correo'] == null) {
            hijoJson['correo'] = '${hijoJson['nombre']?.toLowerCase()}.${hijoJson['apellido']?.toLowerCase()}@estudiante.edu.bo'
                .replaceAll(' ', '.')
                .replaceAll('á', 'a')
                .replaceAll('é', 'e')
                .replaceAll('í', 'i')
                .replaceAll('ó', 'o')
                .replaceAll('ú', 'u')
                .replaceAll('ñ', 'n');
          }
          
          return Estudiante.fromJson(hijoJson);
        }).toList();

        DebugLogger.info('Hijos procesados correctamente', tag: 'PADRE_API');
        return hijos;
        
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else if (response.statusCode == 404) {
        DebugLogger.warning('No se encontraron hijos para este padre', tag: 'PADRE_API');
        return []; // Retornar lista vacía si no hay hijos
      } else {
        throw Exception('Error al obtener los hijos (código ${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      DebugLogger.error('Error de conexión: ${e.message}', tag: 'PADRE_API');
      throw Exception('Error de conexión: ${e.message}');
    } on FormatException catch (e) {
      DebugLogger.error('Error de formato en respuesta: $e', tag: 'PADRE_API');
      throw Exception('Error en el formato de respuesta del servidor');
    } catch (e) {
      DebugLogger.error('Error inesperado: $e', tag: 'PADRE_API');
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  // Método para obtener información académica completa de un hijo
  Future<InfoAcademicaCompleta> getInfoAcademicaCompleta(int hijoId) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/padres/hijo/$hijoId/info-academica-completa';
      
      DebugLogger.info('Obteniendo información académica completa desde: $url', tag: 'PADRE_API');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 20));

      DebugLogger.info('Respuesta obtenida: ${response.statusCode}', tag: 'PADRE_API');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        DebugLogger.info('Información académica obtenida exitosamente', tag: 'PADRE_API');
        
        // Verificar si la respuesta es exitosa
        if (responseData['success'] == true) {
          return InfoAcademicaCompleta.fromJson(responseData);
        } else {
          throw Exception(responseData['mensaje'] ?? 'Error obteniendo información académica');
        }
        
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión nuevamente.');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para ver la información de este estudiante.');
      } else if (response.statusCode == 404) {
        throw Exception('No se encontró información académica para este estudiante.');
      } else {
        throw Exception('Error al obtener información académica (código ${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      DebugLogger.error('Error de conexión: ${e.message}', tag: 'PADRE_API');
      throw Exception('Error de conexión: ${e.message}');
    } on FormatException catch (e) {
      DebugLogger.error('Error de formato en respuesta: $e', tag: 'PADRE_API');
      throw Exception('Error en el formato de respuesta del servidor');
    } catch (e) {
      DebugLogger.error('Error inesperado obteniendo info académica: $e', tag: 'PADRE_API');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  // Método para refrescar la lista de hijos
  Future<List<Estudiante>> refrescarHijos() async {
    DebugLogger.info('Refrescando lista de hijos', tag: 'PADRE_API');
    return await getMisHijos();
  }
}