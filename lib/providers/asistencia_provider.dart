// lib/providers/asistencia_provider.dart
import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';
import '../services/api_service.dart';

class AsistenciaProvider with ChangeNotifier {
  final ApiService? _apiService;
  
  List<Asistencia> _asistencias = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _cursoId;
  bool _isLoading = false;
  String? _errorMessage;

  AsistenciaProvider([this._apiService]) {
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

  Future<void> _cargarAsistencias() async {
    if (_apiService == null) {
      // Modo simulación - cargar datos simulados
      _cargarAsistenciasSimuladas();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_cursoId != null) {
        _asistencias = await _apiService!.getAsistenciaPorCursoYFecha(
          _cursoId!, 
          _fechaSeleccionada
        );
      }
    } catch (e) {
      _errorMessage = 'Error al cargar asistencias: ${e.toString()}';
      _asistencias = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _cargarAsistenciasSimuladas() {
    // Simulación de datos para desarrollo
    final hoy = DateTime.now();
    
    _asistencias = [
      Asistencia(
        id: '1',
        estudianteId: '1',
        cursoId: '1',
        fecha: hoy,
        estado: EstadoAsistencia.presente,
      ),
      Asistencia(
        id: '2',
        estudianteId: '2',
        cursoId: '1',
        fecha: hoy,
        estado: EstadoAsistencia.tardanza,
        observacion: 'Llegó 15 minutos tarde',
      ),
      Asistencia(
        id: '3',
        estudianteId: '3',
        cursoId: '1',
        fecha: hoy,
        estado: EstadoAsistencia.ausente,
      ),
      Asistencia(
        id: '4',
        estudianteId: '4',
        cursoId: '1',
        fecha: hoy,
        estado: EstadoAsistencia.presente,
      ),
      Asistencia(
        id: '5',
        estudianteId: '5',
        cursoId: '1',
        fecha: hoy,
        estado: EstadoAsistencia.justificado,
        observacion: 'Certificado médico',
      ),
    ];
    
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

  Future<void> enviarAsistenciasAlBackend({
    required int docenteId,
    required int cursoId,
    required int materiaId,
    required DateTime fecha,
    required List<dynamic> estudiantes,
  }) async {
    if (_apiService == null) {
      throw Exception('Servicio API no disponible');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Preparar datos para el backend
      List<Map<String, dynamic>> asistenciasData = [];

      for (final estudiante in estudiantes) {
        // Buscar la asistencia del estudiante o usar ausente por defecto
        final asistencia = _asistencias.firstWhere(
          (a) => a.estudianteId == estudiante.id.toString() &&
                 a.fecha.year == fecha.year &&
                 a.fecha.month == fecha.month &&
                 a.fecha.day == fecha.day,
          orElse: () => Asistencia(
            id: '',
            estudianteId: estudiante.id.toString(),
            cursoId: materiaId.toString(),
            fecha: fecha,
            estado: EstadoAsistencia.ausente,
          ),
        );

        asistenciasData.add({
          'id': estudiante.id,
          'estado': _mapearEstadoAsistencia(asistencia.estado),
        });
      }

      // Enviar al backend
      await _apiService!.enviarAsistencias(
        docenteId: docenteId,
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: fecha,
        asistencias: asistenciasData,
      );

    } catch (e) {
      _errorMessage = 'Error al enviar asistencias: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapearEstadoAsistencia(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'presente';
      case EstadoAsistencia.ausente:
        return 'falta';
      case EstadoAsistencia.tardanza:
        return 'tarde';
      case EstadoAsistencia.justificado:
        return 'justificacion';
    }
  }

  Future<void> recargarAsistencias() async {
    await _cargarAsistencias();
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