import 'package:flutter/foundation.dart';
import '../models/periodo.dart';

class PeriodoProvider with ChangeNotifier {
  Periodo? _periodoSeleccionado;
  List<Periodo> _periodos = [];

  PeriodoProvider() {
    _cargarPeriodos();
  }

  Periodo? get periodoSeleccionado => _periodoSeleccionado;
  List<Periodo> get periodos => _periodos;

  void _cargarPeriodos() {
    // Simulación de datos
    _periodos = [
      Periodo(
        id: '1',
        nombre: 'Primer Semestre 2025',
        fechaInicio: DateTime(2025, 1, 1),
        fechaFin: DateTime(2025, 6, 30),
        activo: true,
      ),
      Periodo(
        id: '2',
        nombre: 'Segundo Semestre 2025',
        fechaInicio: DateTime(2025, 7, 1),
        fechaFin: DateTime(2025, 12, 31),
        activo: false,
      ),
    ];
    
    // Seleccionar el periodo activo por defecto
    _periodoSeleccionado = _periodos.firstWhere(
      (periodo) => periodo.activo, 
      orElse: () => _periodos.first
    );
    
    notifyListeners();
  }

  void seleccionarPeriodo(String periodoId) {
    _periodoSeleccionado = _periodos.firstWhere(
      (periodo) => periodo.id == periodoId,
      orElse: () => _periodos.first,
    );
    notifyListeners();
  }
}