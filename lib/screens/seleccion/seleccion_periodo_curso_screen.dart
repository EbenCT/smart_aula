import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/periodo_provider.dart';
import '../../../providers/curso_provider.dart';
import '../../../models/periodo.dart';
import '../../../models/curso.dart';

class SeleccionPeriodoCursoScreen extends StatefulWidget {
  static const routeName = '/seleccion-periodo-curso';

  const SeleccionPeriodoCursoScreen({Key? key}) : super(key: key);

  @override
  _SeleccionPeriodoCursoScreenState createState() =>
      _SeleccionPeriodoCursoScreenState();
}

class _SeleccionPeriodoCursoScreenState
    extends State<SeleccionPeriodoCursoScreen> {
  String? _periodoSeleccionadoId;
  String? _cursoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final periodoProvider =
          Provider.of<PeriodoProvider>(context, listen: false);
      if (periodoProvider.periodoSeleccionado != null) {
        setState(() {
          _periodoSeleccionadoId = periodoProvider.periodoSeleccionado!.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodoProvider = Provider.of<PeriodoProvider>(context);
    final cursoProvider = Provider.of<CursoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Periodo y Curso'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el periodo académico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  value: _periodoSeleccionadoId,
                  hint: const Text('Seleccione un periodo'),
                  isExpanded: true,
                  items: periodoProvider.periodos.map((Periodo periodo) {
                    return DropdownMenuItem<String>(
                      value: periodo.id,
                      child: Text(
                        periodo.nombre,
                        style: TextStyle(
                          fontWeight: periodo.activo
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _periodoSeleccionadoId = newValue;
                      _cursoSeleccionadoId = null;
                    });
                    if (newValue != null) {
                      periodoProvider.seleccionarPeriodo(newValue);
                      cursoProvider.setPeriodoId(newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selecciona el curso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _periodoSeleccionadoId == null
                    ? const Text(
                        'Primero selecciona un periodo',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        value: _cursoSeleccionadoId,
                        hint: const Text('Seleccione un curso'),
                        isExpanded: true,
                        items: cursoProvider
                            .cursosPorPeriodo(_periodoSeleccionadoId!)
                            .map((Curso curso) {
                          return DropdownMenuItem<String>(
                            value: curso.id,
                            child: Text('${curso.codigo} - ${curso.nombre}'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _cursoSeleccionadoId = newValue;
                          });
                          if (newValue != null) {
                            cursoProvider.seleccionarCurso(newValue);
                          }
                        },
                      ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _periodoSeleccionadoId != null &&
                        _cursoSeleccionadoId != null
                    ? () {
                        Navigator.of(context).pushNamed('/home');
                      }
                    : null,
                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}