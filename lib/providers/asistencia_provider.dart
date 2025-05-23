// ignore_for_file: unused_field

import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';

class AsistenciaProvider with ChangeNotifier {
  List<Asistencia> _asistencias = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _cursoId;

  AsistenciaProvider() {
    _cargarAsistencias();
  }

  List<Asistencia> get asistencias => _asistencias;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  
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
    // Simulación de datos
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
}