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

  ResumenProvider(this._apiService);

  // Getters
  ResumenMateriaCompleto? get resumenMateria => _resumenMateria;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get cursoIdActual => _cursoIdActual;
  int? get materiaIdActual => _materiaIdActual;

  // Cargar resumen de materia
  Future<void> cargarResumenMateria(int cursoId, int materiaId) async {
    // Si ya tenemos el resumen de esta materia, no volver a cargar
    if (_cursoIdActual == cursoId && _materiaIdActual == materiaId && _resumenMateria != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.getResumenMateriaCompleto(cursoId, materiaId);
      _resumenMateria = ResumenMateriaCompleto.fromJson(data);
      _cursoIdActual = cursoId;
      _materiaIdActual = materiaId;
    } catch (e) {
      _errorMessage = 'Error al cargar resumen de materia: ${e.toString()}';
      _resumenMateria = null;
      _cursoIdActual = null;
      _materiaIdActual = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recargar resumen actual
  Future<void> recargarResumen() async {
    if (_cursoIdActual != null && _materiaIdActual != null) {
      // Forzar recarga limpiando los IDs actuales
      final cursoId = _cursoIdActual!;
      final materiaId = _materiaIdActual!;
      _cursoIdActual = null;
      _materiaIdActual = null;
      await cargarResumenMateria(cursoId, materiaId);
    }
  }

  // Limpiar datos
  void limpiarResumen() {
    _resumenMateria = null;
    _cursoIdActual = null;
    _materiaIdActual = null;
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
      return 'Cargando resumen...';
    }
    
    if (_errorMessage != null) {
      return 'Error: $_errorMessage';
    }
    
    if (_resumenMateria == null) {
      return 'No hay resumen disponible';
    }
    
    return 'Resumen cargado correctamente';
  }

  // Getters de conveniencia para acceder a los datos del resumen
  int get totalEstudiantes => _resumenMateria?.totalEstudiantes ?? 0;
  
  double get promedioNotasGeneral => _resumenMateria?.promedioGeneral.notas ?? 0.0;
  double get promedioAsistenciaGeneral => _resumenMateria?.promedioGeneral.asistencia ?? 0.0;
  double get promedioParticipacionGeneral => _resumenMateria?.promedioGeneral.participacion ?? 0.0;
  
  ResumenPorPeriodo? get resumenPeriodoActual => _resumenMateria?.resumenPeriodoActual;
  
  bool get tieneNotas => _resumenMateria?.tieneNotas ?? false;
  bool get tieneAsistencia => _resumenMateria?.tieneAsistencia ?? false;
  bool get tieneParticipacion => _resumenMateria?.tieneParticipacion ?? false;
}