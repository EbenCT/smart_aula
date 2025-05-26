// lib/providers/resumen_estudiante_provider.dart
import 'package:flutter/foundation.dart';
import '../models/resumen_estudiante.dart';
import '../services/api_service.dart';

class ResumenEstudianteProvider with ChangeNotifier {
  final ApiService _apiService;
  
  // Cache de resúmenes por estudiante
  final Map<String, ResumenEstudiante> _resumenesCache = {};
  bool _isLoading = false;
  String? _errorMessage;

  ResumenEstudianteProvider(this._apiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Obtener resumen de un estudiante específico
  Future<ResumenEstudiante?> getResumenEstudiante({
    required int estudianteId,
    required int materiaId,
    int? periodoId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${estudianteId}_${materiaId}_${periodoId ?? 'null'}';
    
    // Si ya tenemos el resumen en cache y no forzamos refresh, devolverlo
    if (!forceRefresh && _resumenesCache.containsKey(cacheKey)) {
      return _resumenesCache[cacheKey];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.resumenEstudiante.getResumenPorEstudiante(
        estudianteId: estudianteId,
        materiaId: materiaId,
        periodoId: periodoId,
      );
      
      final resumen = ResumenEstudiante.fromJson(data);
      
      // Guardar en cache
      _resumenesCache[cacheKey] = resumen;
      
      return resumen;
    } catch (e) {
      _errorMessage = 'Error al cargar resumen del estudiante: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener resumen desde cache (sin hacer petición)
  ResumenEstudiante? getResumenFromCache({
    required int estudianteId,
    required int materiaId,
    int? periodoId,
  }) {
    final cacheKey = '${estudianteId}_${materiaId}_${periodoId ?? 'null'}';
    return _resumenesCache[cacheKey];
  }

  // Limpiar cache
  void clearCache() {
    _resumenesCache.clear();
    notifyListeners();
  }

  // Limpiar cache de un estudiante específico
  void clearStudentCache(int estudianteId) {
    _resumenesCache.removeWhere((key, value) => key.startsWith('${estudianteId}_'));
    notifyListeners();
  }

  // Verificar si hay resumen en cache
  bool hasCache({
    required int estudianteId,
    required int materiaId,
    int? periodoId,
  }) {
    final cacheKey = '${estudianteId}_${materiaId}_${periodoId ?? 'null'}';
    return _resumenesCache.containsKey(cacheKey);
  }

  // Precargar resúmenes para una lista de estudiantes
  Future<void> preloadEstudiantesResumen({
    required List<int> estudianteIds,
    required int materiaId,
    int? periodoId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = estudianteIds.map((estudianteId) async {
        final cacheKey = '${estudianteId}_${materiaId}_${periodoId ?? 'null'}';
        
        // Solo cargar si no está en cache
        if (!_resumenesCache.containsKey(cacheKey)) {
          try {
            final data = await _apiService.resumenEstudiante.getResumenPorEstudiante(
              estudianteId: estudianteId,
              materiaId: materiaId,
              periodoId: periodoId,
            );
            
            final resumen = ResumenEstudiante.fromJson(data);
            _resumenesCache[cacheKey] = resumen;
          } catch (e) {
            // Si falla uno, continuar con los demás
            print('Error cargando resumen para estudiante $estudianteId: $e');
          }
        }
      });

      await Future.wait(futures);
    } catch (e) {
      _errorMessage = 'Error al precargar resúmenes: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener estadísticas rápidas para mostrar en la lista
  Map<String, dynamic> getEstadisticasRapidas({
    required int estudianteId,
    required int materiaId,
    int? periodoId,
  }) {
    final resumen = getResumenFromCache(
      estudianteId: estudianteId,
      materiaId: materiaId,
      periodoId: periodoId,
    );

    if (resumen == null) {
      return {
        'promedioGeneral': 0.0,
        'porcentajeAsistencia': 0.0,
        'totalEvaluaciones': 0,
        'tieneResumen': false,
      };
    }

    return {
      'promedioGeneral': resumen.promedioGeneral,
      'porcentajeAsistencia': resumen.asistencia?.porcentaje ?? 0.0,
      'totalEvaluaciones': resumen.evaluacionesAcademicas.length,
      'tieneResumen': true,
    };
  }
}