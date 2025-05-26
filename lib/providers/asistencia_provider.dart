// lib/providers/asistencia_provider.dart
// ignore_for_file: unused_field

import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';
import '../services/api_service.dart';

class AsistenciaProvider with ChangeNotifier {
  final ApiService? _apiService;
  
  List<Asistencia> _asistencias = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _cursoId;
  int? _materiaId;
  bool _isLoading = false;
  String? _errorMessage;

  AsistenciaProvider([this._apiService]);

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

  void setMateriaId(int materiaId) {
    _materiaId = materiaId;
    notifyListeners();
  }

  void setFechaSeleccionada(DateTime fecha) {
    _fechaSeleccionada = fecha;
    notifyListeners();
  }

  // Cargar asistencias desde el backend
  Future<void> cargarAsistenciasDesdeBackend({
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
  }) async {
    if (_apiService == null) {
      _errorMessage = 'Servicio API no disponible';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Cargando asistencias para: curso=$cursoId, materia=$materiaId, fecha=$fecha');
      
      final response = await _apiService.evaluaciones.getAsistenciasMasivas(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: fecha,
      );

      print('Respuesta del backend: $response');

      // Limpiar asistencias existentes para esta fecha
      _asistencias.removeWhere((a) => 
        a.fecha.year == fecha.year && 
        a.fecha.month == fecha.month && 
        a.fecha.day == fecha.day
      );

      // Procesar las asistencias del backend
      if (response['asistencias'] != null) {
        final asistenciasBackend = response['asistencias'] as List<dynamic>;
        print('Número de asistencias encontradas: ${asistenciasBackend.length}');
        
        for (final asistenciaData in asistenciasBackend) {
          try {
            print('Procesando asistencia: $asistenciaData');
            
            // Validar que los campos requeridos existen
            if (asistenciaData['id'] == null || 
                asistenciaData['estudiante_id'] == null || 
                asistenciaData['fecha'] == null ||
                asistenciaData['valor'] == null) {
              print('Datos incompletos en asistencia: $asistenciaData');
              continue;
            }
            
            final asistencia = Asistencia(
              id: asistenciaData['id'].toString(),
              estudianteId: asistenciaData['estudiante_id'].toString(),
              cursoId: materiaId.toString(), // Usamos materiaId como cursoId para compatibilidad
              fecha: DateTime.parse(asistenciaData['fecha']),
              estado: _apiService.evaluaciones.mapearEstadoDesdeBackend(asistenciaData['valor']),
              observacion: asistenciaData['descripcion'],
            );
            
            _asistencias.add(asistencia);
            print('Asistencia agregada exitosamente para estudiante: ${asistencia.estudianteId}');
          } catch (e) {
            print('Error procesando asistencia individual: $e');
            print('Datos de asistencia problemática: $asistenciaData');
            // Continuar con el siguiente registro aunque uno falle
          }
        }
      } else {
        print('No se encontraron asistencias en la respuesta');
      }

      _cursoId = materiaId.toString();
      _materiaId = materiaId;
      _fechaSeleccionada = fecha;

      print('Asistencias cargadas exitosamente. Total: ${_asistencias.length}');

    } catch (e) {
      _errorMessage = 'Error al cargar asistencias: ${e.toString()}';
      print('Error completo cargando asistencias: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  // Obtener asistencia de un estudiante específico para la fecha actual
  Asistencia? getAsistenciaEstudiante(String estudianteId, DateTime fecha) {
    try {
      return _asistencias.firstWhere((a) => 
        a.estudianteId == estudianteId && 
        a.fecha.year == fecha.year && 
        a.fecha.month == fecha.month && 
        a.fecha.day == fecha.day
      );
    } catch (e) {
      return null;
    }
  }

  // Verificar si hay asistencias cargadas para la fecha y materia actual
  bool tieneAsistenciasCargadas(int cursoId, int materiaId, DateTime fecha) {
    return _asistencias.any((a) => 
      a.cursoId == materiaId.toString() && 
      a.fecha.year == fecha.year && 
      a.fecha.month == fecha.month && 
      a.fecha.day == fecha.day
    );
  }
}