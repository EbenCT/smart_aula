// lib/providers/participacion_provider.dart
import 'package:flutter/foundation.dart';
import '../models/participacion.dart';
import '../services/api_service.dart';

class ParticipacionProvider with ChangeNotifier {
  final ApiService? _apiService;
  
  List<Participacion> _participaciones = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _cursoId;
  int? _materiaId;
  bool _isLoading = false;
  String? _errorMessage;

  ParticipacionProvider([this._apiService]);

  List<Participacion> get participaciones => _participaciones;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  List<Participacion> participacionesPorCursoYFecha(String cursoId, DateTime fecha) {
    return _participaciones.where((p) => 
      p.cursoId == cursoId && 
      p.fecha.year == fecha.year && 
      p.fecha.month == fecha.month && 
      p.fecha.day == fecha.day
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

  // Cargar participaciones desde el backend
  Future<void> cargarParticipacionesDesdeBackend({
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
      print('Cargando participaciones para: curso=$cursoId, materia=$materiaId, fecha=$fecha');
      
      final response = await _apiService.evaluaciones.getParticipacionesMasivas(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: fecha,
      );

      print('Respuesta del backend: $response');

      // Limpiar participaciones existentes para esta fecha
      _participaciones.removeWhere((p) => 
        p.fecha.year == fecha.year && 
        p.fecha.month == fecha.month && 
        p.fecha.day == fecha.day
      );

      // Procesar las participaciones del backend
      if (response['evaluaciones'] != null) {
        final participacionesBackend = response['evaluaciones'] as List<dynamic>;
        print('Número de participaciones encontradas: ${participacionesBackend.length}');
        
        for (final participacionData in participacionesBackend) {
          try {
            print('Procesando participación: $participacionData');
            
            // Validar que los campos requeridos existen
            if (participacionData['id'] == null || 
                participacionData['estudiante_id'] == null || 
                participacionData['fecha'] == null ||
                participacionData['valor'] == null) {
              print('Datos incompletos en participación: $participacionData');
              continue;
            }
            
            final participacion = Participacion(
              id: participacionData['id'].toString(),
              estudianteId: participacionData['estudiante_id'].toString(),
              cursoId: materiaId.toString(), // Usamos materiaId como cursoId para compatibilidad
              fecha: DateTime.parse(participacionData['fecha']),
              valoracion: (participacionData['valor'] is double) 
                  ? (participacionData['valor'] as double).toInt() 
                  : (participacionData['valor'] as int),
              descripcion: participacionData['descripcion'] ?? 'Participación',
              tipo: TipoParticipacion.comentario, // Por defecto
            );
            
            _participaciones.add(participacion);
            print('Participación agregada exitosamente para estudiante: ${participacion.estudianteId}');
          } catch (e) {
            print('Error procesando participación individual: $e');
            print('Datos de participación problemática: $participacionData');
            // Continuar con el siguiente registro aunque uno falle
          }
        }
      } else {
        print('No se encontraron participaciones en la respuesta');
      }

      _cursoId = materiaId.toString();
      _materiaId = materiaId;
      _fechaSeleccionada = fecha;

      print('Participaciones cargadas exitosamente. Total: ${_participaciones.length}');

    } catch (e) {
      _errorMessage = 'Error al cargar participaciones: ${e.toString()}';
      print('Error completo cargando participaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void registrarParticipacion(Participacion participacion) {
    // Buscar si ya existe una participación para ese estudiante, curso y fecha
    final index = _participaciones.indexWhere((p) => 
      p.estudianteId == participacion.estudianteId && 
      p.cursoId == participacion.cursoId && 
      p.fecha.year == participacion.fecha.year && 
      p.fecha.month == participacion.fecha.month && 
      p.fecha.day == participacion.fecha.day
    );
    
    if (index >= 0) {
      // Actualizar existente
      _participaciones[index] = participacion;
    } else {
      // Agregar nueva
      _participaciones.add(participacion);
    }
    
    notifyListeners();
  }

  void limpiarParticipaciones() {
    _participaciones.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // Método para obtener estadísticas rápidas
  Map<String, dynamic> getEstadisticasParticipacion(String cursoId, DateTime fecha) {
    final participacionesFecha = participacionesPorCursoYFecha(cursoId, fecha);
    
    final participacionesConValor = participacionesFecha.where((p) => p.valoracion > 0).toList();
    final totalPuntaje = participacionesConValor.fold<int>(0, (sum, p) => sum + p.valoracion);
    final promedioPuntaje = participacionesConValor.isNotEmpty ? totalPuntaje / participacionesConValor.length : 0.0;
    
    return {
      'total': participacionesFecha.length,
      'conParticipacion': participacionesConValor.length,
      'sinParticipacion': participacionesFecha.where((p) => p.valoracion == 0).length,
      'promedioPuntaje': promedioPuntaje,
    };
  }

  // Método para verificar si hay cambios pendientes de guardar
  bool get tieneCambiosPendientes => _participaciones.isNotEmpty;

  // Obtener participación de un estudiante específico para la fecha actual
  Participacion? getParticipacionEstudiante(String estudianteId, DateTime fecha) {
    try {
      return _participaciones.firstWhere((p) => 
        p.estudianteId == estudianteId && 
        p.fecha.year == fecha.year && 
        p.fecha.month == fecha.month && 
        p.fecha.day == fecha.day
      );
    } catch (e) {
      return null;
    }
  }

  // Verificar si hay participaciones cargadas para la fecha y materia actual
  bool tieneParticipacionesCargadas(int cursoId, int materiaId, DateTime fecha) {
    return _participaciones.any((p) => 
      p.cursoId == materiaId.toString() && 
      p.fecha.year == fecha.year && 
      p.fecha.month == fecha.month && 
      p.fecha.day == fecha.day
    );
  }

  // Obtener todas las participaciones de un estudiante para la fecha seleccionada
  List<Participacion> getParticipacionesEstudiante(String estudianteId, DateTime fecha) {
    return _participaciones.where((p) => 
      p.estudianteId == estudianteId && 
      p.fecha.year == fecha.year && 
      p.fecha.month == fecha.month && 
      p.fecha.day == fecha.day
    ).toList();
  }

  // Eliminar participación específica
  void eliminarParticipacion(Participacion participacion) {
    _participaciones.remove(participacion);
    notifyListeners();
  }

  // Actualizar participación existente
  void actualizarParticipacion(Participacion participacionAnterior, Participacion participacionNueva) {
    final index = _participaciones.indexOf(participacionAnterior);
    if (index >= 0) {
      _participaciones[index] = participacionNueva;
      notifyListeners();
    }
  }
}