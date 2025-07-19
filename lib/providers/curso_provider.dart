// lib/providers/curso_provider.dart
import 'package:flutter/foundation.dart';
import '../models/curso.dart';
import '../models/materia.dart';
import '../services/api_service.dart';

class  CursoProvider with ChangeNotifier {
  final ApiService _apiService;
  
  Curso? _cursoSeleccionado;
  Materia? _materiaSeleccionada;
  List<Curso> _cursos = [];
  List<Materia> _materias = [];
  bool _isLoadingCursos = false;
  bool _isLoadingMaterias = false;
  String? _errorMessage;
  DateTime? _lastCursosLoadTime;
  final Map<int, DateTime> _materiasLoadTimes = {};

  CursoProvider(this._apiService);

  // Getters
  Curso? get cursoSeleccionado => _cursoSeleccionado;
  Materia? get materiaSeleccionada => _materiaSeleccionada;
  List<Curso> get cursos => _cursos;
  List<Materia> get materias => _materias;
  bool get isLoadingCursos => _isLoadingCursos;
  bool get isLoadingMaterias => _isLoadingMaterias;
  String? get errorMessage => _errorMessage;

  // Verificar si el cache de cursos está fresco (30 minutos)
  bool _isCursosCacheFresh() {
    if (_lastCursosLoadTime == null) return false;
    final now = DateTime.now();
    return now.difference(_lastCursosLoadTime!).inMinutes < 30;
  }

  // Verificar si el cache de materias está fresco (15 minutos)
  bool _isMateriasCacheFresh(int cursoId) {
    if (!_materiasLoadTimes.containsKey(cursoId)) return false;
    final now = DateTime.now();
    return now.difference(_materiasLoadTimes[cursoId]!).inMinutes < 15;
  }

  // Cargar cursos del docente con optimización
  Future<void> cargarCursosDocente({bool forceRefresh = false}) async {
    // Si tenemos cursos frescos y no forzamos refresh, no recargar
    if (!forceRefresh && _cursos.isNotEmpty && _isCursosCacheFresh()) {
      return;
    }

    // Evitar múltiples cargas simultáneas
    if (_isLoadingCursos) {
      return;
    }

    _setLoadingCursosState(true);
    _errorMessage = null;

    try {
      final cursosNuevos = await _apiService.getCursosDocente();
      
      // Verificar que la respuesta no esté vacía
      if (cursosNuevos.isEmpty && _cursos.isNotEmpty) {
        throw Exception('No se encontraron cursos');
      }
      
      _cursos = cursosNuevos;
      _lastCursosLoadTime = DateTime.now();
      
      // Verificar si el curso seleccionado aún existe
      if (_cursoSeleccionado != null) {
        final cursoExiste = _cursos.any((c) => c.id == _cursoSeleccionado!.id);
        if (!cursoExiste) {
          _limpiarSelecciones();
        }
      }
      
    } catch (e) {
      _errorMessage = _formatError(e.toString(), 'cursos');
      
      // No limpiar cursos existentes si es un error temporal
      if (!_isTemporaryError(e.toString()) && _cursos.isEmpty) {
        _limpiarSelecciones();
      }
    } finally {
      _setLoadingCursosState(false);
    }
  }

  // Cargar materias de un curso específico con optimización
  Future<void> cargarMateriasCurso(int cursoId, {bool forceRefresh = false}) async {
    // Si tenemos materias frescas para este curso, no recargar
    if (!forceRefresh && _materias.isNotEmpty && _isMateriasCacheFresh(cursoId)) {
      return;
    }

    // Evitar múltiples cargas simultáneas
    if (_isLoadingMaterias) {
      return;
    }

    _setLoadingMateriasState(true);
    _errorMessage = null;

    try {
      final materiasNuevas = await _apiService.getMateriasDocente(cursoId);
      
      _materias = materiasNuevas;
      _materiasLoadTimes[cursoId] = DateTime.now();
      
      // Verificar si la materia seleccionada aún existe
      if (_materiaSeleccionada != null) {
        final materiaExiste = _materias.any((m) => m.id == _materiaSeleccionada!.id);
        if (!materiaExiste) {
          _materiaSeleccionada = null;
        }
      }
      
    } catch (e) {
      _errorMessage = _formatError(e.toString(), 'materias');
      
      if (!_isTemporaryError(e.toString())) {
        _materias.clear();
        _materiaSeleccionada = null;
      }
    } finally {
      _setLoadingMateriasState(false);
    }
  }

  // Seleccionar curso de forma optimizada
  void seleccionarCurso(int cursoId) {
    final curso = _cursos.firstWhere(
      (curso) => curso.id == cursoId,
      orElse: () => throw Exception('Curso no encontrado'),
    );
    
    // Solo actualizar si es diferente
    if (_cursoSeleccionado?.id != cursoId) {
      _cursoSeleccionado = curso;
      
      // Limpiar materia seleccionada y materias cuando se cambia el curso
      _materiaSeleccionada = null;
      _materias.clear();
      
      notifyListeners();
      
      // Cargar materias del nuevo curso en background
      cargarMateriasCurso(cursoId);
    }
  }

  // Seleccionar materia de forma optimizada
  void seleccionarMateria(int materiaId) {
    final materia = _materias.firstWhere(
      (materia) => materia.id == materiaId,
      orElse: () => throw Exception('Materia no encontrada'),
    );
    
    // Solo actualizar si es diferente
    if (_materiaSeleccionada?.id != materiaId) {
      _materiaSeleccionada = materia;
      notifyListeners();
    }
  }

  // Métodos privados para optimizar notificaciones
  void _setLoadingCursosState(bool loading) {
    if (_isLoadingCursos != loading) {
      _isLoadingCursos = loading;
      notifyListeners();
    }
  }

  void _setLoadingMateriasState(bool loading) {
    if (_isLoadingMaterias != loading) {
      _isLoadingMaterias = loading;
      notifyListeners();
    }
  }

  // Limpiar selecciones
  void _limpiarSelecciones() {
    _cursoSeleccionado = null;
    _materiaSeleccionada = null;
    _materias.clear();
  }

  // Limpiar selecciones (método público)
  void limpiarSelecciones() {
    _limpiarSelecciones();
    notifyListeners();
  }

  // Verificar si es un error temporal
  bool _isTemporaryError(String error) {
    return error.toLowerCase().contains('timeout') ||
           error.toLowerCase().contains('conexión') ||
           error.toLowerCase().contains('internet');
  }

  // Formatear mensaje de error más conciso
  String _formatError(String error, String context) {
    final cleanError = error.replaceFirst('Exception: ', '');
    
    if (cleanError.contains('timeout')) {
      return 'Conexión lenta';
    } else if (cleanError.contains('conexión') || cleanError.contains('internet')) {
      return 'Sin conexión';
    } else if (cleanError.contains(context)) {
      return 'Error al cargar $context';
    } else {
      return cleanError.length > 40 ? '${cleanError.substring(0, 37)}...' : cleanError;
    }
  }

  // Verificar si hay una selección completa
  bool get tieneSeleccionCompleta => 
      _cursoSeleccionado != null && _materiaSeleccionada != null;

  // Obtener texto descriptivo de la selección actual
  String get textoSeleccionActual {
    if (_cursoSeleccionado == null) {
      return 'Sin curso seleccionado';
    }
    
    if (_materiaSeleccionada == null) {
      return '${_cursoSeleccionado!.nombreCompleto} - Sin materia';
    }
    
    return '${_cursoSeleccionado!.nombreCompleto} - ${_materiaSeleccionada!.nombre}';
  }

  // Invalidar cache manualmente
  void invalidarCache() {
    _lastCursosLoadTime = null;
    _materiasLoadTimes.clear();
  }

  // Precargar datos en background
  Future<void> precargarDatos() async {
    if (_cursos.isEmpty || !_isCursosCacheFresh()) {
      cargarCursosDocente();
    }
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'cursos': {
      'count': _cursos.length,
      'ultimaCarga': _lastCursosLoadTime?.toIso8601String(),
      'esFresco': _isCursosCacheFresh(),
    },
    'materias': {
      'count': _materias.length,
      'ultimasCarga': _materiasLoadTimes.map((key, value) => MapEntry(key.toString(), value.toIso8601String())),
    },
    'seleccion': {
      'curso': _cursoSeleccionado?.id,
      'materia': _materiaSeleccionada?.id,
      'completa': tieneSeleccionCompleta,
    }
  };
}