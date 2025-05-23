import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/constants.dart';
import '../models/curso.dart';
import '../models/materia.dart';
import '../models/asistencia.dart';
import '../models/estudiante.dart';
import '../models/participacion.dart';
import '../models/periodo.dart';
import './auth_service.dart';

class ApiService {
  final AuthService _authService;
  
  ApiService(this._authService);
  
  // Obtener encabezados con autenticación para las solicitudes
  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
  
  // Método genérico para hacer solicitudes GET
  Future<dynamic> get(String endpoint) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes POST
  Future<dynamic> post(String endpoint, dynamic data) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes PUT
  Future<dynamic> put(String endpoint, dynamic data) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Método genérico para hacer solicitudes DELETE
  Future<dynamic> delete(String endpoint) async {
    final url = '${AppConstants.apiBaseUrl}$endpoint';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }
  
  // Procesar respuesta HTTP
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Si la respuesta está vacía, retornamos un mapa vacío
      if (response.body.isEmpty) {
        return {};
      }
      
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expirado o no válido, deslogueamos al usuario
      _authService.logout();
      throw Exception('Sesión expirada. Por favor, inicie sesión nuevamente.');
    } else {
      String message;
      try {
        final data = json.decode(response.body);
        
        // Manejar errores de validación de FastAPI
        if (data is Map && data.containsKey('detail')) {
          if (data['detail'] is List) {
            // Error de validación con múltiples campos
            final errors = data['detail'] as List;
            message = errors.map((e) => e['msg'] ?? 'Error de validación').join(', ');
          } else if (data['detail'] is String) {
            // Error simple con mensaje string
            message = data['detail'];
          } else {
            message = 'Error en la solicitud';
          }
        } else {
          message = data['mensaje'] ?? data['message'] ?? 'Error en la solicitud';
        }
      } catch (e) {
        message = 'Error en la solicitud: ${response.statusCode}';
      }
      
      throw Exception(message);
    }
  }
  
  // Manejar errores de red
  void _handleError(dynamic error) {
    String message = 'Error de conexión';
    
    if (error is Exception) {
      message = error.toString();
    }
    
    // Errores comunes
    if (message.contains('SocketException')) {
      message = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    } else if (message.contains('timeout')) {
      message = 'La conexión al servidor ha tardado demasiado. Inténtalo más tarde.';
    }
    
    throw Exception(message);
  }

  // CURSOS DEL DOCENTE
  Future<List<Curso>> getCursosDocente() async {
    try {
      final userId = _authService.usuario?.id ?? _authService.userId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await get('/docentes/cursos-docente/$userId');
      
      if (response is List) {
        return response.map((json) => Curso.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener los cursos: $e');
    }
  }

  // MATERIAS DEL DOCENTE POR CURSO
  Future<List<Materia>> getMateriasDocente(int cursoId) async {
    try {
      final userId = _authService.usuario?.id ?? _authService.userId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await get('/docentes/$userId/curso/$cursoId/materias');
      
      if (response is List) {
        return response.map((json) => Materia.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener las materias: $e');
    }
  }

  // PERIODOS (mantenemos para compatibilidad pero puede no usarse)
  Future<List<Periodo>> getPeriodos() async {
    try {
      // Para el desarrollo, devolvemos datos simulados
      return _getPeriodsSimulados();
      
      // En producción, usar el siguiente código:
      /*
      final response = await get('/periodos');
      
      if (response is List) {
        return response.map((json) => Periodo.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
      */
    } catch (e) {
      throw Exception('Error al obtener los periodos: $e');
    }
  }

  // ESTUDIANTES POR MATERIA
  Future<List<Estudiante>> getEstudiantesPorMateria(int cursoId, int materiaId) async {
    try {
      final userId = _authService.usuario?.id ?? _authService.userId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await get('/docentes/alumnos-docente/$userId/curso/$cursoId/materia/$materiaId');
      
      if (response is List) {
        return response.map((json) => Estudiante.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener los estudiantes: $e');
    }
  }

  // ESTUDIANTES (método legacy para compatibilidad)
  Future<List<Estudiante>> getEstudiantesPorCurso(String cursoId) async {
    try {
      // Para desarrollo, devolvemos datos simulados
      return _getEstudiantesSimulados(cursoId);
      
      // En producción, este método podría no usarse más
    } catch (e) {
      throw Exception('Error al obtener los estudiantes: $e');
    }
  }

  // ASISTENCIA (por ahora mantenemos la simulación)
  Future<List<Asistencia>> getAsistenciaPorCursoYFecha(
    String cursoId, 
    DateTime fecha
  ) async {
    try {
      // Para desarrollo, devolvemos datos simulados
      return _getAsistenciaSimulada(cursoId, fecha);
      
      // En producción, usar el siguiente código:
      /*
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final response = await get('/cursos/$cursoId/asistencia?fecha=$fechaStr');
      
      if (response is List) {
        return response.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
      */
    } catch (e) {
      throw Exception('Error al obtener la asistencia: $e');
    }
  }

  Future<void> registrarAsistencia(Asistencia asistencia) async {
    try {
      // Para desarrollo, no hacemos nada
      await Future.delayed(const Duration(milliseconds: 300));
      
      // En producción, usar el siguiente código:
      /*
      await post('/asistencia', asistencia.toJson());
      */
    } catch (e) {
      throw Exception('Error al registrar la asistencia: $e');
    }
  }

  // PARTICIPACIONES (por ahora mantenemos la simulación)
  Future<List<Participacion>> getParticipacionesPorEstudiante(
    String estudianteId,
    String cursoId,
  ) async {
    try {
      // Para desarrollo, devolvemos datos simulados
      return _getParticipacionesSimuladas(estudianteId, cursoId);
      
      // En producción, usar el siguiente código:
      /*
      final response = await get('/estudiantes/$estudianteId/cursos/$cursoId/participaciones');
      
      if (response is List) {
        return response.map((json) => Participacion.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inesperado');
      }
      */
    } catch (e) {
      throw Exception('Error al obtener las participaciones: $e');
    }
  }

  Future<void> registrarParticipacion(Participacion participacion) async {
    try {
      // Para desarrollo, no hacemos nada
      await Future.delayed(const Duration(milliseconds: 300));
      
      // En producción, usar el siguiente código:
      /*
      await post('/participaciones', participacion.toJson());
      */
    } catch (e) {
      throw Exception('Error al registrar la participación: $e');
    }
  }

  // UTILIDADES DE SIMULACIÓN (solo para desarrollo)
  
  List<Periodo> _getPeriodsSimulados() {
    return [
      Periodo(
        id: '1',
        nombre: 'Primer Semestre 2025',
        fechaInicio: DateTime(2025, 1, 1),
        fechaFin: DateTime(2025, 6, 30),
        activo: true,
      ),
      Periodo(
        id: '2',
        nombre: 'Segundo Semestre 2025',
        fechaInicio: DateTime(2025, 7, 1),
        fechaFin: DateTime(2025, 12, 31),
        activo: false,
      ),
    ];
  }

  List<Estudiante> _getEstudiantesSimulados(String cursoId) {
    return [
      Estudiante(
        id: 1,
        nombre: 'Juan',
        apellido: 'Pérez García',
        fechaNacimiento: DateTime(2005, 3, 15),
        genero: 'Masculino',
        urlImagen: null,
        nombreTutor: 'María García',
        telefonoTutor: '+591 70123456',
        direccionCasa: 'Av. América #123, La Paz',
        notas: {'parcial1': 85, 'parcial2': 90},
        porcentajeAsistencia: 95,
        participaciones: 12,
        prediccion: {
          'valorNumerico': 88.5,
          'nivel': 'alto',
          'factoresInfluyentes': ['Alta participación', 'Buena asistencia']
        },
      ),
      Estudiante(
        id: 2,
        nombre: 'María',
        apellido: 'López Mamani',
        fechaNacimiento: DateTime(2005, 7, 22),
        genero: 'Femenino',
        urlImagen: null,
        nombreTutor: 'Carlos López',
        telefonoTutor: '+591 71234567',
        direccionCasa: 'Calle Comercio #456, El Alto',
        notas: {'parcial1': 75, 'parcial2': 68},
        porcentajeAsistencia: 80,
        participaciones: 5,
        prediccion: {
          'valorNumerico': 72.0,
          'nivel': 'medio',
          'factoresInfluyentes': ['Baja participación']
        },
      ),
      Estudiante(
        id: 3,
        nombre: 'Carlos',
        apellido: 'Quispe Condori',
        fechaNacimiento: DateTime(2005, 11, 8),
        genero: 'Masculino',
        urlImagen: null,
        nombreTutor: 'Ana Condori',
        telefonoTutor: '+591 72345678',
        direccionCasa: 'Zona Villa Fátima #789, La Paz',
        notas: {'parcial1': 45, 'parcial2': 55},
        porcentajeAsistencia: 60,
        participaciones: 2,
        prediccion: {
          'valorNumerico': 49.0,
          'nivel': 'bajo',
          'factoresInfluyentes': ['Baja asistencia', 'Pocas participaciones']
        },
      ),
      Estudiante(
        id: 4,
        nombre: 'Ana',
        apellido: 'Martínez Flores',
        fechaNacimiento: DateTime(2005, 1, 12),
        genero: 'Femenino',
        urlImagen: null,
        nombreTutor: 'Roberto Martínez',
        telefonoTutor: '+591 73456789',
        direccionCasa: 'Av. 6 de Agosto #321, La Paz',
        notas: {'parcial1': 92, 'parcial2': 95},
        porcentajeAsistencia: 98,
        participaciones: 15,
        prediccion: {
          'valorNumerico': 94.0,
          'nivel': 'alto',
          'factoresInfluyentes': ['Excelente asistencia', 'Alta participación']
        },
      ),
      Estudiante(
        id: 5,
        nombre: 'Pedro',
        apellido: 'Ramírez Choque',
        fechaNacimiento: DateTime(2005, 9, 30),
        genero: 'Masculino',
        urlImagen: null,
        nombreTutor: 'Elena Choque',
        telefonoTutor: '+591 74567890',
        direccionCasa: 'Calle Sagárnaga #654, La Paz',
        notas: {'parcial1': 60, 'parcial2': 65},
        porcentajeAsistencia: 75,
        participaciones: 4,
        prediccion: {
          'valorNumerico': 63.0,
          'nivel': 'medio',
          'factoresInfluyentes': ['Asistencia regular']
        },
      ),
    ];
  }

  List<Asistencia> _getAsistenciaSimulada(String cursoId, DateTime fecha) {
    final hoy = DateTime.now();
    if (fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day) {
      return [
        Asistencia(
          id: '1',
          estudianteId: '1',
          cursoId: cursoId,
          fecha: hoy,
          estado: EstadoAsistencia.presente,
        ),
        Asistencia(
          id: '2',
          estudianteId: '2',
          cursoId: cursoId,
          fecha: hoy,
          estado: EstadoAsistencia.tardanza,
          observacion: 'Llegó 15 minutos tarde',
        ),
        Asistencia(
          id: '3',
          estudianteId: '3',
          cursoId: cursoId,
          fecha: hoy,
          estado: EstadoAsistencia.ausente,
        ),
        Asistencia(
          id: '4',
          estudianteId: '4',
          cursoId: cursoId,
          fecha: hoy,
          estado: EstadoAsistencia.presente,
        ),
        Asistencia(
          id: '5',
          estudianteId: '5',
          cursoId: cursoId,
          fecha: hoy,
          estado: EstadoAsistencia.justificado,
          observacion: 'Certificado médico',
        ),
      ];
    }
    
    // Para otras fechas, retornamos lista vacía
    return [];
  }

  List<Participacion> _getParticipacionesSimuladas(
    String estudianteId, 
    String cursoId
  ) {
    final hoy = DateTime.now();
    
    if (estudianteId == '1') {
      return [
        Participacion(
          id: '1',
          estudianteId: estudianteId,
          cursoId: cursoId,
          fecha: hoy.subtract(const Duration(hours: 1)),
          tipo: TipoParticipacion.respuesta,
          valoracion: 5,
          descripcion: 'Respuesta completa a problema complejo',
        ),
        Participacion(
          id: '2',
          estudianteId: estudianteId,
          cursoId: cursoId,
          fecha: hoy.subtract(const Duration(days: 1)),
          tipo: TipoParticipacion.pregunta,
          valoracion: 4,
          descripcion: 'Pregunta relevante sobre el tema',
        ),
      ];
    } else if (estudianteId == '4') {
      return [
        Participacion(
          id: '3',
          estudianteId: estudianteId,
          cursoId: cursoId,
          fecha: hoy,
          tipo: TipoParticipacion.presentacion,
          valoracion: 5,
          descripcion: 'Excelente presentación del tema asignado',
        ),
      ];
    }
    
    // Para otros estudiantes, lista vacía
    return [];
  }
}