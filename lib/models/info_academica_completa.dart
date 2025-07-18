// lib/models/info_academica_completa.dart

class EstudianteBasico {
  final int id;
  final String nombre;
  final String apellido;
  final String? correo;

  EstudianteBasico({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.correo,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory EstudianteBasico.fromJson(Map<String, dynamic> json) {
    return EstudianteBasico(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      correo: json['correo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
    };
  }
}

class DocenteBasico {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String? telefono;

  DocenteBasico({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.telefono,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory DocenteBasico.fromJson(Map<String, dynamic> json) {
    return DocenteBasico(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      correo: json['correo'],
      telefono: json['telefono'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'telefono': telefono,
    };
  }
}

class MateriaBasica {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? sigla;

  MateriaBasica({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.sigla,
  });

  factory MateriaBasica.fromJson(Map<String, dynamic> json) {
    return MateriaBasica(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      sigla: json['sigla'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'sigla': sigla,
    };
  }
}

class CursoBasico {
  final int id;
  final String nombre;
  final String nivel;
  final String paralelo;
  final String turno;

  CursoBasico({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.paralelo,
    required this.turno,
  });

  factory CursoBasico.fromJson(Map<String, dynamic> json) {
    return CursoBasico(
      id: json['id'],
      nombre: json['nombre'],
      nivel: json['nivel'],
      paralelo: json['paralelo'],
      turno: json['turno'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nivel': nivel,
      'paralelo': paralelo,
      'turno': turno,
    };
  }
}

class GestionBasica {
  final int id;
  final String anio;
  final String descripcion;

  GestionBasica({
    required this.id,
    required this.anio,
    required this.descripcion,
  });

  factory GestionBasica.fromJson(Map<String, dynamic> json) {
    return GestionBasica(
      id: json['id'],
      anio: json['anio'].toString(),
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anio': anio,
      'descripcion': descripcion,
    };
  }
}

class InscripcionBasica {
  final int id;
  final String descripcion;
  final DateTime fecha;

  InscripcionBasica({
    required this.id,
    required this.descripcion,
    required this.fecha,
  });

  factory InscripcionBasica.fromJson(Map<String, dynamic> json) {
    return InscripcionBasica(
      id: json['id'],
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String().split('T')[0],
    };
  }
}

class MateriaConDocente {
  final MateriaBasica materia;
  final DocenteBasico? docente;

  MateriaConDocente({
    required this.materia,
    this.docente,
  });

  factory MateriaConDocente.fromJson(Map<String, dynamic> json) {
    return MateriaConDocente(
      materia: MateriaBasica.fromJson(json['materia']),
      docente: json['docente'] != null 
          ? DocenteBasico.fromJson(json['docente']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materia': materia.toJson(),
      'docente': docente?.toJson(),
    };
  }
}

class EstadisticasAcademicas {
  final int totalMaterias;
  final int materiasConDocente;
  final int materiasSinDocente;
  final int totalDocentesUnicos;

  EstadisticasAcademicas({
    required this.totalMaterias,
    required this.materiasConDocente,
    required this.materiasSinDocente,
    required this.totalDocentesUnicos,
  });

  factory EstadisticasAcademicas.fromJson(Map<String, dynamic> json) {
    return EstadisticasAcademicas(
      totalMaterias: json['total_materias'],
      materiasConDocente: json['materias_con_docente'],
      materiasSinDocente: json['materias_sin_docente'],
      totalDocentesUnicos: json['total_docentes_unicos'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_materias': totalMaterias,
      'materias_con_docente': materiasConDocente,
      'materias_sin_docente': materiasSinDocente,
      'total_docentes_unicos': totalDocentesUnicos,
    };
  }
}

class InfoAcademicaCompleta {
  final EstudianteBasico estudiante;
  final InscripcionBasica inscripcion;
  final CursoBasico curso;
  final GestionBasica gestion;
  final List<MateriaConDocente> materias;
  final EstadisticasAcademicas estadisticas;
  final String mensaje;

  InfoAcademicaCompleta({
    required this.estudiante,
    required this.inscripcion,
    required this.curso,
    required this.gestion,
    required this.materias,
    required this.estadisticas,
    required this.mensaje,
  });

  factory InfoAcademicaCompleta.fromJson(Map<String, dynamic> json) {
    final infoAcademica = json['info_academica'];
    
    return InfoAcademicaCompleta(
      estudiante: EstudianteBasico.fromJson(infoAcademica['estudiante']),
      inscripcion: InscripcionBasica.fromJson(infoAcademica['inscripcion']),
      curso: CursoBasico.fromJson(infoAcademica['curso']),
      gestion: GestionBasica.fromJson(infoAcademica['gestion']),
      materias: (infoAcademica['materias'] as List)
          .map((materia) => MateriaConDocente.fromJson(materia))
          .toList(),
      estadisticas: EstadisticasAcademicas.fromJson(json['estadisticas']),
      mensaje: json['mensaje'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': true,
      'info_academica': {
        'estudiante': estudiante.toJson(),
        'inscripcion': inscripcion.toJson(),
        'curso': curso.toJson(),
        'gestion': gestion.toJson(),
        'materias': materias.map((m) => m.toJson()).toList(),
      },
      'estadisticas': estadisticas.toJson(),
      'mensaje': mensaje,
    };
  }
}