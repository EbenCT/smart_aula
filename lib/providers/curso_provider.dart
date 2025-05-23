import 'package:flutter/foundation.dart';
import '../models/curso.dart';
import '../models/materia.dart';
import '../services/api_service.dart';

class CursoProvider with ChangeNotifier {
  final ApiService _apiService;
  
  Curso? _cursoSeleccionado;
  Materia? _materiaSeleccionada;
  List<Curso> _cursos = [];
  List<Materia> _materias = [];
  bool _isLoadingCursos = false;
  bool _isLoadingMaterias = false;
  String? _errorMessage;

  CursoProvider(this._apiService);

  // Getters
  Curso? get cursoSeleccionado => _cursoSeleccionado;
  Materia? get materiaSeleccionada => _materiaSeleccionada;
  List<Curso> get cursos => _cursos;
  List<Materia> get materias => _materias;
  bool get isLoadingCursos => _isLoadingCursos;
  bool get isLoadingMaterias => _isLoadingMaterias;
  String? get errorMessage => _errorMessage;

  // Cargar cursos del docente
  Future<void> cargarCursosDocente() async {
    _isLoadingCursos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cursos = await _apiService.getCursosDocente();
      
      // Si había un curso seleccionado, verificar que aún existe
      if (_cursoSeleccionado != null) {
        final cursoExiste = _cursos.any((c) => c.id == _cursoSeleccionado!.id);
        if (!cursoExiste) {
          _cursoSeleccionado = null;
          _materiaSeleccionada = null;
          _materias.clear();
        }
      }
      
    } catch (e) {
      _errorMessage = 'Error al cargar cursos: ${e.toString()}';
      _cursos.clear();
      _cursoSeleccionado = null;
      _materiaSeleccionada = null;
      _materias.clear();
    } finally {
      _isLoadingCursos = false;
      notifyListeners();
    }
  }

  // Cargar materias de un curso específico
  Future<void> cargarMateriasCurso(int cursoId) async {
    _isLoadingMaterias = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _materias = await _apiService.getMateriasDocente(cursoId);
      
      // Si había una materia seleccionada, verificar que aún existe
      if (_materiaSeleccionada != null) {
        final materiaExiste = _materias.any((m) => m.id == _materiaSeleccionada!.id);
        if (!materiaExiste) {
          _materiaSeleccionada = null;
        }
      }
      
    } catch (e) {
      _errorMessage = 'Error al cargar materias: ${e.toString()}';
      _materias.clear();
      _materiaSeleccionada = null;
    } finally {
      _isLoadingMaterias = false;
      notifyListeners();
    }
  }

  // Seleccionar curso
  void seleccionarCurso(int cursoId) {
    _cursoSeleccionado = _cursos.firstWhere(
      (curso) => curso.id == cursoId,
      orElse: () => throw Exception('Curso no encontrado'),
    );
    
    // Limpiar materia seleccionada y materias cuando se cambia el curso
    _materiaSeleccionada = null;
    _materias.clear();
    
    notifyListeners();
    
    // Cargar materias del nuevo curso
    cargarMateriasCurso(cursoId);
  }

  // Seleccionar materia
  void seleccionarMateria(int materiaId) {
    _materiaSeleccionada = _materias.firstWhere(
      (materia) => materia.id == materiaId,
      orElse: () => throw Exception('Materia no encontrada'),
    );
    notifyListeners();
  }

  // Limpiar selecciones
  void limpiarSelecciones() {
    _cursoSeleccionado = null;
    _materiaSeleccionada = null;
    _materias.clear();
    notifyListeners();
  }

  // Verificar si hay una selección completa
  bool get tieneSeleccionCompleta => 
      _cursoSeleccionado != null && _materiaSeleccionada != null;

  // Obtener texto descriptivo de la selección actual
  String get textoSeleccionActual {
    if (_cursoSeleccionado == null) {
      return 'Ningún curso seleccionado';
    }
    
    if (_materiaSeleccionada == null) {
      return '${_cursoSeleccionado!.nombreCompleto} - Ninguna materia seleccionada';
    }
    
    return '${_cursoSeleccionado!.nombreCompleto} - ${_materiaSeleccionada!.nombre}';
  }
}