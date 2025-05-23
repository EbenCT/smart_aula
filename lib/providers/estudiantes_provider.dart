import 'package:flutter/foundation.dart';
import '../models/estudiante.dart';
import '../services/api_service.dart';

class EstudiantesProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<Estudiante> _estudiantes = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _cursoIdActual;
  int? _materiaIdActual;

  EstudiantesProvider(this._apiService);

  // Getters
  List<Estudiante> get estudiantes => _estudiantes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get cursoIdActual => _cursoIdActual;
  int? get materiaIdActual => _materiaIdActual;

  // Cargar estudiantes por materia
  Future<void> cargarEstudiantesPorMateria(int cursoId, int materiaId) async {
    // Si ya tenemos los estudiantes de esta materia, no volver a cargar
    if (_cursoIdActual == cursoId && _materiaIdActual == materiaId && _estudiantes.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _estudiantes = await _apiService.getEstudiantesPorMateria(cursoId, materiaId);
      _cursoIdActual = cursoId;
      _materiaIdActual = materiaId;
    } catch (e) {
      _errorMessage = 'Error al cargar estudiantes: ${e.toString()}';
      _estudiantes.clear();
      _cursoIdActual = null;
      _materiaIdActual = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener estudiante por ID
  Estudiante? getEstudiantePorId(int id) {
    try {
      return _estudiantes.firstWhere((estudiante) => estudiante.id == id);
    } catch (e) {
      return null;
    }
  }

  // Limpiar datos
  void limpiarEstudiantes() {
    _estudiantes.clear();
    _cursoIdActual = null;
    _materiaIdActual = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Recargar estudiantes actuales
  Future<void> recargarEstudiantes() async {
    if (_cursoIdActual != null && _materiaIdActual != null) {
      // Forzar recarga limpiando los IDs actuales
      final cursoId = _cursoIdActual!;
      final materiaId = _materiaIdActual!;
      _cursoIdActual = null;
      _materiaIdActual = null;
      await cargarEstudiantesPorMateria(cursoId, materiaId);
    }
  }

  // Buscar estudiantes por término
  List<Estudiante> buscarEstudiantes(String termino) {
    if (termino.isEmpty) return _estudiantes;
    
    final terminoLower = termino.toLowerCase();
    return _estudiantes.where((estudiante) {
      return estudiante.nombreCompleto.toLowerCase().contains(terminoLower) ||
             estudiante.codigo.toLowerCase().contains(terminoLower) ||
             estudiante.email.toLowerCase().contains(terminoLower);
    }).toList();
  }

  // Verificar si hay estudiantes cargados para la materia actual
  bool get tieneEstudiantesCargados => 
      _cursoIdActual != null && 
      _materiaIdActual != null && 
      _estudiantes.isNotEmpty;

  // Obtener texto descriptivo del estado actual
  String get estadoActual {
    if (_isLoading) {
      return 'Cargando estudiantes...';
    }
    
    if (_errorMessage != null) {
      return 'Error: $_errorMessage';
    }
    
    if (_estudiantes.isEmpty) {
      return 'No hay estudiantes registrados';
    }
    
    return '${_estudiantes.length} estudiante(s) cargado(s)';
  }
}