// lib/providers/asistencia_provider.dart
// ignore_for_file: unused_field

import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';

class AsistenciaProvider with ChangeNotifier {
  List<Asistencia> _asistencias = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _cursoId;
  bool _isLoading = false;
  String? _errorMessage;

  AsistenciaProvider() {
    _cargarAsistencias();
  }

  List<Asistencia> get asistencias => _asistencias;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  List<Asistencia> asistenciasPorCursoYFecha(String cursoId, DateTime fecha) {
    return _asistencias.where((a) => 
      a.cursoId == cursoId && 
      a.fecha.year == fecha.year && 
      a.fecha.month == fecha.month && 
      a.fecha.day == fecha.day
    ).toList();
  }

  void setCursoId(String cursoId) {
    _cursoId = cursoId;
    notifyListeners();
  }

  void setFechaSeleccionada(DateTime fecha) {
    _fechaSeleccionada = fecha;
    notifyListeners();
  }

  void _cargarAsistencias() {
    // Para desarrollo, iniciamos con lista vacía
    // Las asistencias se cargarán cuando el usuario las registre
    _asistencias = [];
    notifyListeners();
  }

  void registrarAsistencia(Asistencia asistencia) {
    // Buscar si ya existe una asistencia para ese estudiante, curso y fecha
    final index = _asistencias.indexWhere((a) => 
      a.estudianteId == asistencia.estudianteId && 
      a.cursoId == asistencia.cursoId && 
      a.fecha.year == asistencia.fecha.year && 
      a.fecha.month == asistencia.fecha.month && 
      a.fecha.day == asistencia.fecha.day
    );
    
    if (index >= 0) {
      // Actualizar existente
      _asistencias[index] = asistencia;
    } else {
      // Agregar nueva
      _asistencias.add(asistencia);
    }
    
    notifyListeners();
  }

  void limpiarAsistencias() {
    _asistencias.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // Método para obtener estadísticas rápidas
  Map<String, int> getEstadisticasAsistencia(String cursoId, DateTime fecha) {
    final asistenciasFecha = asistenciasPorCursoYFecha(cursoId, fecha);
    
    return {
      'presentes': asistenciasFecha.where((a) => a.estado == EstadoAsistencia.presente).length,
      'tardanzas': asistenciasFecha.where((a) => a.estado == EstadoAsistencia.tardanza).length,
      'ausentes': asistenciasFecha.where((a) => a.estado == EstadoAsistencia.ausente).length,
      'justificados': asistenciasFecha.where((a) => a.estado == EstadoAsistencia.justificado).length,
    };
  }

  // Método para verificar si hay cambios pendientes de guardar
  bool get tieneCambiosPendientes => _asistencias.isNotEmpty;
}