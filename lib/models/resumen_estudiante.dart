// lib/models/resumen_estudiante.dart

class DetalleEvaluacion {
  final String fecha;
  final String descripcion;
  final double valor;

  DetalleEvaluacion({
    required this.fecha,
    required this.descripcion,
    required this.valor,
  });

  factory DetalleEvaluacion.fromJson(Map<String, dynamic> json) {
    return DetalleEvaluacion(
      fecha: json['fecha'] ?? '',
      descripcion: json['descripcion'] ?? '',
      valor: (json['valor'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'descripcion': descripcion,
      'valor': valor,
    };
  }
}

class TipoEvaluacion {
  final int id;
  final String nombre;
  final double? promedio;
  final double? porcentaje; // Para asistencia
  final int total;
  final List<DetalleEvaluacion> detalle;

  TipoEvaluacion({
    required this.id,
    required this.nombre,
    this.promedio,
    this.porcentaje,
    required this.total,
    required this.detalle,
  });

  factory TipoEvaluacion.fromJson(int id, Map<String, dynamic> json) {
    return TipoEvaluacion(
      id: id,
      nombre: json['nombre'] ?? '',
      promedio: json['promedio'] != null ? (json['promedio'] as num).toDouble() : null,
      porcentaje: json['porcentaje'] != null ? (json['porcentaje'] as num).toDouble() : null,
      total: json['total'] ?? 0,
      detalle: (json['detalle'] as List<dynamic>?)
          ?.map((item) => DetalleEvaluacion.fromJson(item))
          .toList() ?? [],
    );
  }

  // Getter para obtener el valor principal (promedio o porcentaje)
  double get valorPrincipal => promedio ?? porcentaje ?? 0.0;

  // Getter para verificar si es asistencia
  bool get esAsistencia => nombre.toLowerCase().contains('asistencia');

  // Getter para obtener color según el valor
  String get colorIndicador {
    final valor = valorPrincipal;
    if (esAsistencia) {
      // Para asistencia: verde >= 90%, amarillo >= 75%, rojo < 75%
      if (valor >= 90) return 'verde';
      if (valor >= 75) return 'amarillo';
      return 'rojo';
    } else {
      // Para notas: verde >= 80, amarillo >= 60, rojo < 60
      if (valor >= 80) return 'verde';
      if (valor >= 60) return 'amarillo';
      return 'rojo';
    }
  }

  // Getter para texto descriptivo del rendimiento
  String get textoRendimiento {
    final valor = valorPrincipal;
    if (esAsistencia) {
      if (valor >= 90) return 'Excelente';
      if (valor >= 75) return 'Bueno';
      return 'Deficiente';
    } else {
      if (valor >= 80) return 'Excelente';
      if (valor >= 60) return 'Bueno';
      return 'Necesita mejorar';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'promedio': promedio,
      'porcentaje': porcentaje,
      'total': total,
      'detalle': detalle.map((item) => item.toJson()).toList(),
    };
  }
}

class ResumenEstudiante {
  final String fecha;
  final int periodoId;
  final Map<int, TipoEvaluacion> resumen;

  ResumenEstudiante({
    required this.fecha,
    required this.periodoId,
    required this.resumen,
  });

  factory ResumenEstudiante.fromJson(Map<String, dynamic> json) {
    final Map<int, TipoEvaluacion> resumenMap = {};
    
    if (json['resumen'] != null) {
      final resumenData = json['resumen'] as Map<String, dynamic>;
      resumenData.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is Map<String, dynamic>) {
          resumenMap[id] = TipoEvaluacion.fromJson(id, value);
        }
      });
    }

    return ResumenEstudiante(
      fecha: json['fecha'] ?? '',
      periodoId: json['periodo_id'] ?? 1,
      resumen: resumenMap,
    );
  }

  // Getter para obtener todas las evaluaciones ordenadas por ID
  List<TipoEvaluacion> get evaluacionesOrdenadas {
    final evaluaciones = resumen.values.toList();
    evaluaciones.sort((a, b) => a.id.compareTo(b.id));
    return evaluaciones;
  }

  // Getter para obtener solo las evaluaciones académicas (excluyendo asistencia)
  List<TipoEvaluacion> get evaluacionesAcademicas {
    return evaluacionesOrdenadas.where((e) => !e.esAsistencia).toList();
  }

  // Getter para obtener la asistencia
  TipoEvaluacion? get asistencia {
    return evaluacionesOrdenadas.firstWhere(
      (e) => e.esAsistencia,
      orElse: () => TipoEvaluacion(
        id: 0,
        nombre: 'Asistencia',
        porcentaje: 0.0,
        total: 0,
        detalle: [],
      ),
    );
  }

  // Calcular promedio general de evaluaciones académicas
  double get promedioGeneral {
    final academicas = evaluacionesAcademicas;
    if (academicas.isEmpty) return 0.0;
    
    double suma = 0.0;
    int count = 0;
    
    for (final evaluacion in academicas) {
      if (evaluacion.promedio != null) {
        suma += evaluacion.promedio!;
        count++;
      }
    }
    
    return count > 0 ? suma / count : 0.0;
  }

  // Verificar si tiene datos de evaluaciones
  bool get tieneEvaluaciones => evaluacionesAcademicas.isNotEmpty;

  // Verificar si tiene datos de asistencia
  bool get tieneAsistencia => asistencia != null && asistencia!.total > 0;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> resumenJson = {};
    resumen.forEach((key, value) {
      resumenJson[key.toString()] = value.toJson();
    });

    return {
      'fecha': fecha,
      'periodo_id': periodoId,
      'resumen': resumenJson,
    };
  }
}