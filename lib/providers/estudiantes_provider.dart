// lib/providers/estudiantes_provider.dart
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
  DateTime? _lastLoadTime;

  EstudiantesProvider(this._apiService);

  // Getters
  List<Estudiante> get estudiantes => _estudiantes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get cursoIdActual => _cursoIdActual;
  int? get materiaIdActual => _materiaIdActual;

  // Verificar si los datos están actualizados (cache de 10 minutos)
  bool _isDataFresh() {
    if (_lastLoadTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastLoadTime!);
    return difference.inMinutes < 10; // Cache de 10 minutos
  }

  // Cargar estudiantes por materia con optimización
  Future<void> cargarEstudiantesPorMateria(int cursoId, int materiaId, {bool forceRefresh = false}) async {
    // Si ya tenemos los estudiantes de esta materia y están frescos, no volver a cargar
    if (!forceRefresh && 
        _cursoIdActual == cursoId && 
        _materiaIdActual == materiaId && 
        _estudiantes.isNotEmpty && 
        _isDataFresh()) {
      return;
    }

    // Si ya estamos cargando, no iniciar otra carga
    if (_isLoading) {
      return;
    }

    _setLoadingState(true);

    try {
      _estudiantes = await _apiService.getEstudiantesPorMateria(cursoId, materiaId);
      _cursoIdActual = cursoId;
      _materiaIdActual = materiaId;
      _lastLoadTime = DateTime.now();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _formatError(e.toString());
      
      // Solo limpiar datos si es un error grave, no por timeout o conexión
      if (!_isTemporaryError(e.toString())) {
        _estudiantes.clear();
        _cursoIdActual = null;
        _materiaIdActual = null;
        _lastLoadTime = null;
      }
    } finally {
      _setLoadingState(false);
    }
  }

  // Verificar si es un error temporal
  bool _isTemporaryError(String error) {
    return error.toLowerCase().contains('timeout') ||
           error.toLowerCase().contains('conexión') ||
           error.toLowerCase().contains('internet');
  }

  // Formatear mensaje de error más conciso
  String _formatError(String error) {
    final cleanError = error.replaceFirst('Exception: ', '');
    
    if (cleanError.contains('estudiantes')) {
      return 'Error al cargar estudiantes';
    } else if (cleanError.contains('timeout')) {
      return 'Conexión lenta, intenta de nuevo';
    } else if (cleanError.contains('conexión') || cleanError.contains('internet')) {
      return 'Revisa tu conexión';
    } else {
      return cleanError.length > 50 ? '${cleanError.substring(0, 47)}...' : cleanError;
    }
  }

  // Método optimizado para establecer estado de carga
  void _setLoadingState(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Obtener estudiante por ID (optimizado con búsqueda local primero)
  Estudiante? getEstudiantePorId(int id) {
    try {
      return _estudiantes.firstWhere((estudiante) => estudiante.id == id);
    } catch (e) {
      return null;
    }
  }

  // Limpiar datos con preservación opcional
  void limpiarEstudiantes({bool preserveCache = false}) {
    if (!preserveCache) {
      _estudiantes.clear();
      _cursoIdActual = null;
      _materiaIdActual = null;
      _lastLoadTime = null;
    }
    _errorMessage = null;
    notifyListeners();
  }

  // Recargar estudiantes actuales de forma inteligente
  Future<void> recargarEstudiantes({bool force = false}) async {
    if (_cursoIdActual != null && _materiaIdActual != null) {
      await cargarEstudiantesPorMateria(_cursoIdActual!, _materiaIdActual!, forceRefresh: force);
    }
  }

  // Buscar estudiantes por término (optimizado)
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
      return 'Cargando...';
    }
    
    if (_errorMessage != null) {
      return _errorMessage!;
    }
    
    if (_estudiantes.isEmpty) {
      return 'Sin estudiantes';
    }
    
    return '${_estudiantes.length} estudiante(s)';
  }

  // Precargar estudiantes en background si es necesario
  Future<void> precargarSiEsNecesario(int cursoId, int materiaId) async {
    if (_cursoIdActual != cursoId || 
        _materiaIdActual != materiaId || 
        _estudiantes.isEmpty ||
        !_isDataFresh()) {
      
      // Cargar en background sin mostrar loading
      try {
        final estudiantes = await _apiService.getEstudiantesPorMateria(cursoId, materiaId);
        
        // Solo actualizar si no hay datos más recientes
        if (_cursoIdActual == cursoId && _materiaIdActual == materiaId) {
          _estudiantes = estudiantes;
          _lastLoadTime = DateTime.now();
          notifyListeners();
        }
      } catch (e) {
        // Fallar silenciosamente en precarga
        print('Precarga de estudiantes falló: $e');
      }
    }
  }

  // Invalidar cache manualmente
  void invalidarCache() {
    _lastLoadTime = null;
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'tieneDatos': _estudiantes.isNotEmpty,
    'ultimaCarga': _lastLoadTime?.toIso8601String(),
    'esFresco': _isDataFresh(),
    'curso': _cursoIdActual,
    'materia': _materiaIdActual,
  };
}