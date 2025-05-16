//import 'package:http/http.dart' as http;
import '../models/periodo.dart';
import '../models/curso.dart';
import '../models/estudiante.dart';
import '../models/asistencia.dart';
import '../models/participacion.dart';

class ApiService {
  // URL base de la API (cambiar en producción)
  static const baseUrl = 'https://api.aulainteligente.example.com';
  
  //final http.Client _client = http.Client();
  final String? _token;

  ApiService(this._token);

  // Encabezados comunes para las solicitudes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // PERIODOS
  Future<List<Periodo>> getPeriodos() async {
    try {
      // Para el desarrollo, devolvemos datos simulados
      return _getPeriodsSimulados();
      
      // En producción, usar el siguiente código:
      /*
      final response = await _client.get(
        Uri.parse('$baseUrl/periodos'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Periodo.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener los periodos: ${response.statusCode}');
      }
      */
    } catch (e) {
      throw Exception('Error al obtener los periodos: $e');
    }
  }

  // CURSOS
  Future<List<Curso>> getCursosPorPeriodo(String periodoId) async {
    try {
      // Para desarrollo, devolvemos datos simulados
      return _getCursosSimulados(periodoId);
      
      // En producción, usar el siguiente código:
      /*
      final response = await _client.get(
        Uri.parse('$baseUrl/periodos/$periodoId/cursos'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Curso.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener los cursos: ${response.statusCode}');
      }
      */
    } catch (e) {
      throw Exception('Error al obtener los cursos: $e');
    }
  }

  // ESTUDIANTES
  Future<List<Estudiante>> getEstudiantesPorCurso(String cursoId) async {
    try {
      // Para desarrollo, devolvemos datos simulados
      return _getEstudiantesSimulados(cursoId);
      
      // En producción, usar el siguiente código:
      /*
      final response = await _client.get(
        Uri.parse('$baseUrl/cursos/$cursoId/estudiantes'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Estudiante.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener los estudiantes: ${response.statusCode}');
      }
      */
    } catch (e) {
      throw Exception('Error al obtener los estudiantes: $e');
    }
  }

  // ASISTENCIA
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
      final response = await _client.get(
        Uri.parse('$baseUrl/cursos/$cursoId/asistencia?fecha=$fechaStr'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener la asistencia: ${response.statusCode}');
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
      final response = await _client.post(
        Uri.parse('$baseUrl/asistencia'),
        headers: _headers,
        body: json.encode(asistencia.toJson()),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al registrar la asistencia: ${response.statusCode}');
      }
      */
    } catch (e) {
      throw Exception('Error al registrar la asistencia: $e');
    }
  }

  // PARTICIPACIONES
  Future<List<Participacion>> getParticipacionesPorEstudiante(
    String estudianteId,
    String cursoId,
  ) async {
    try {
      // Para desarrollo, devolvemos datos simulados
      return _getParticipacionesSimuladas(estudianteId, cursoId);
      
      // En producción, usar el siguiente código:
      /*
      final response = await _client.get(
        Uri.parse('$baseUrl/estudiantes/$estudianteId/cursos/$cursoId/participaciones'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Participacion.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener las participaciones: ${response.statusCode}');
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
      final response = await _client.post(
        Uri.parse('$baseUrl/participaciones'),
        headers: _headers,
        body: json.encode(participacion.toJson()),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al registrar la participación: ${response.statusCode}');
      }
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

  List<Curso> _getCursosSimulados(String periodoId) {
    return [
      Curso(
        id: '1',
        nombre: 'Matemáticas Avanzadas',
        codigo: 'MAT101',
        periodoId: '1',
      ),
      Curso(
        id: '2',
        nombre: 'Programación I',
        codigo: 'CS101',
        periodoId: '1',
      ),
      Curso(
        id: '3',
        nombre: 'Física Aplicada',
        codigo: 'FIS201',
        periodoId: '1',
      ),
      Curso(
        id: '4',
        nombre: 'Estadística',
        codigo: 'EST101',
        periodoId: '2',
      ),
    ].where((curso) => curso.periodoId == periodoId).toList();
  }

  List<Estudiante> _getEstudiantesSimulados(String cursoId) {
    return [
      Estudiante(
        id: '1',
        nombre: 'Juan',
        apellido: 'Pérez',
        codigo: 'EST001',
        email: 'juan.perez@mail.com',
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
        id: '2',
        nombre: 'María',
        apellido: 'García',
        codigo: 'EST002',
        email: 'maria.garcia@mail.com',
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
        id: '3',
        nombre: 'Carlos',
        apellido: 'López',
        codigo: 'EST003',
        email: 'carlos.lopez@mail.com',
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
        id: '4',
        nombre: 'Ana',
        apellido: 'Martínez',
        codigo: 'EST004',
        email: 'ana.martinez@mail.com',
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
        id: '5',
        nombre: 'Pedro',
        apellido: 'Ramírez',
        codigo: 'EST005',
        email: 'pedro.ramirez@mail.com',
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