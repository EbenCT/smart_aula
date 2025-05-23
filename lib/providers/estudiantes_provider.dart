// ignore_for_file: unused_field

import 'package:flutter/foundation.dart';
import '../models/estudiante.dart';

class EstudiantesProvider with ChangeNotifier {
  List<Estudiante> _estudiantes = [];
  String? _cursoId;

  EstudiantesProvider() {
    _cargarEstudiantes();
  }

  List<Estudiante> get estudiantes => _estudiantes;
  List<Estudiante> estudiantesPorCurso(String cursoId) {
    // En un escenario real, aquí filtraríamos por curso
    // Por ahora, devolvemos todos para simular
    return _estudiantes;
  }

  void setCursoId(String cursoId) {
    _cursoId = cursoId;
    notifyListeners();
  }

  void _cargarEstudiantes() {
    // Simulación de datos
    _estudiantes = [
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
    ];
    
    notifyListeners();
  }

  Estudiante getEstudiantePorId(String id) {
    return _estudiantes.firstWhere(
      (estudiante) => estudiante.id == id,
      orElse: () => throw Exception('Estudiante no encontrado'),
    );
  }
}