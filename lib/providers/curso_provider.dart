import 'package:flutter/foundation.dart';
import '../models/curso.dart';

class CursoProvider with ChangeNotifier {
  Curso? _cursoSeleccionado;
  List<Curso> _cursos = [];
  String? _periodoId;

  CursoProvider() {
    _cargarCursos();
  }

  Curso? get cursoSeleccionado => _cursoSeleccionado;
  List<Curso> get cursos => _cursos;
  List<Curso> cursosPorPeriodo(String periodoId) => 
      _cursos.where((curso) => curso.periodoId == periodoId).toList();

  void setPeriodoId(String periodoId) {
    _periodoId = periodoId;
    _cursoSeleccionado = null;
    notifyListeners();
  }

  void _cargarCursos() {
    // Simulación de datos
    _cursos = [
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
    ];
    
    notifyListeners();
  }

  void seleccionarCurso(String cursoId) {
    _cursoSeleccionado = _cursos.firstWhere(
      (curso) => curso.id == cursoId,
      orElse: () => _cursos.first,
    );
    notifyListeners();
  }
}