// lib/providers/resumen_provider.dart
import 'package:flutter/foundation.dart';
import '../models/resumen_materia.dart';
import '../services/api_service.dart';

class ResumenProvider with ChangeNotifier {
  final ApiService _apiService;
  
  ResumenMateriaCompleto? _resumenMateria;
  bool _isLoading = false;
  String? _errorMessage;
  int? _cursoIdActual;
  int? _materiaIdActual;
  DateTime? _lastLoadTime;

  ResumenProvider(this._apiService);

  // Getters
  ResumenMateriaCompleto? get resumenMateria => _resumenMateria;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get cursoIdActual => _cursoIdActual;
  int? get materiaIdActual => _materiaIdActual;

  // Verificar si los datos están frescos (cache de 15 minutos)
  bool _isDataFresh() {
    if (_lastLoadTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastLoadTime!);
    return difference.inMinutes < 15;
  }

  // Cargar resumen de materia con optimización
  Future<void> cargarResumenMateria(int cursoId, int materiaId, {bool forceRefresh = false}) async {
    // Si ya tenemos el resumen de esta materia y está fresco, no volver a cargar
    if (!forceRefresh && 
        _cursoIdActual == cursoId && 
        _materiaIdActual == materiaId && 
        _resumenMateria != null && 
        _isDataFresh()) {
      return;
    }

    // Evitar cargas simultáneas
    if (_isLoading) return;

    _setLoadingState(true);
    _errorMessage = null;

    try {
      final data = await _apiService.getResumenMateriaCompleto(cursoId, materiaId);
      _resumenMateria = ResumenMateriaCompleto.fromJson(data);
      _cursoIdActual = cursoId;
      _materiaIdActual = materiaId;
      _lastLoadTime = DateTime.now();
    } catch (e) {
      _errorMessage = _formatError(e.toString());
      
      // Solo limpiar datos si es un error grave, no por timeout o conexión
      if (!_isTemporaryError(e.toString())) {
        _resumenMateria = null;
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
    
    if (cleanError.contains('resumen')) {
      return 'Error al cargar resumen';
    } else if (cleanError.contains('timeout')) {
      return 'Conexión lenta';
    } else if (cleanError.contains('conexión') || cleanError.contains('internet')) {
      return 'Sin conexión';
    } else {
      return cleanError.length > 40 ? '${cleanError.substring(0, 37)}...' : cleanError;
    }
  }

  // Método optimizado para establecer estado de carga
  void _setLoadingState(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Recargar resumen actual de forma inteligente
  Future<void> recargarResumen({bool force = false}) async {
    if (_cursoIdActual != null && _materiaIdActual != null) {
      await cargarResumenMateria(_cursoIdActual!, _materiaIdActual!, forceRefresh: force);
    }
  }

  // Limpiar datos con preservación opcional
  void limpiarResumen({bool preserveCache = false}) {
    if (!preserveCache) {
      _resumenMateria = null;
      _cursoIdActual = null;
      _materiaIdActual = null;
      _lastLoadTime = null;
    }
    _errorMessage = null;
    notifyListeners();
  }

  // Verificar si hay resumen cargado para la materia actual
  bool get tieneResumenCargado => 
      _cursoIdActual != null && 
      _materiaIdActual != null && 
      _resumenMateria != null;

  // Obtener texto descriptivo del estado actual
  String get estadoActual {
    if (_isLoading) {
      return 'Cargando...';
    }
    
    if (_errorMessage != null) {
      return _errorMessage!;
    }
    
    if (_resumenMateria == null) {
      return 'Sin datos';
    }
    
    return 'Resumen cargado';
  }

  // Getters de conveniencia para acceso rápido a datos
  int get totalEstudiantes => _resumenMateria?.totalEstudiantes ?? 0;
  
  double get promedioNotasGeneral => _resumenMateria?.promedioGeneral.notas ?? 0.0;
  double get promedioAsistenciaGeneral => _resumenMateria?.promedioGeneral.asistencia ?? 0.0;
  double get promedioParticipacionGeneral => _resumenMateria?.promedioGeneral.participacion ?? 0.0;
  
  ResumenPorPeriodo? get resumenPeriodoActual => _resumenMateria?.resumenPeriodoActual;
  
  bool get tieneNotas => _resumenMateria?.tieneNotas ?? false;
  bool get tieneAsistencia => _resumenMateria?.tieneAsistencia ?? false;
  bool get tieneParticipacion => _resumenMateria?.tieneParticipacion ?? false;

  // Precargar resumen en background si es necesario
  Future<void> precargarSiEsNecesario(int cursoId, int materiaId) async {
    if (_cursoIdActual != cursoId || 
        _materiaIdActual != materiaId || 
        _resumenMateria == null ||
        !_isDataFresh()) {
      
      // Cargar en background sin mostrar loading
      try {
        final data = await _apiService.getResumenMateriaCompleto(cursoId, materiaId);
        
        // Solo actualizar si no hay datos más recientes
        if (_cursoIdActual == cursoId && _materiaIdActual == materiaId) {
          _resumenMateria = ResumenMateriaCompleto.fromJson(data);
          _lastLoadTime = DateTime.now();
          notifyListeners();
        }
      } catch (e) {
        // Fallar silenciosamente en precarga
        debugPrint('Precarga de resumen falló: $e');
      }
    }
  }

  // Invalidar cache manualmente
  void invalidarCache() {
    _lastLoadTime = null;
  }

  // Obtener información de cache
  Map<String, dynamic> get cacheInfo => {
    'tieneResumen': _resumenMateria != null,
    'ultimaCarga': _lastLoadTime?.toIso8601String(),
    'esFresco': _isDataFresh(),
    'curso': _cursoIdActual,
    'materia': _materiaIdActual,
  };
}