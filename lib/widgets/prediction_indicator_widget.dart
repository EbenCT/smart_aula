import 'package:flutter/material.dart';
import '../models/prediccion.dart';

class PredictionIndicatorWidget extends StatelessWidget {
  final Map<String, dynamic>? prediccion;
  final double size;
  final bool showLabel;

  const PredictionIndicatorWidget({
    Key? key,
    required this.prediccion,
    this.size = 40,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (prediccion == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 16,
          ),
        ),
      );
    }

    final nivel = NivelRendimiento.values.firstWhere(
      (e) => e.toString().split('.').last == prediccion!['nivel'],
      orElse: () => NivelRendimiento.medio,
    );

    final color = _getColorForNivel(nivel);
    final valor = prediccion!['valorNumerico']?.toString() ?? '?';

    Widget indicator = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valor,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.3,
              ),
            ),
            if (showLabel && size > 60)
              Text(
                _getNivelTexto(nivel),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.15,
                ),
              ),
          ],
        ),
      ),
    );

    if (showLabel && size <= 60) {
      return Column(
        children: [
          indicator,
          const SizedBox(height: 4),
          Text(
            _getNivelTexto(nivel),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      );
    }

    return indicator;
  }

  Color _getColorForNivel(NivelRendimiento nivel) {
    switch (nivel) {
      case NivelRendimiento.bajo:
        return Colors.red;
      case NivelRendimiento.medio:
        return Colors.amber;
      case NivelRendimiento.alto:
        return Colors.green;
    }
  }

  String _getNivelTexto(NivelRendimiento nivel) {
    switch (nivel) {
      case NivelRendimiento.bajo:
        return 'BAJO';
      case NivelRendimiento.medio:
        return 'MEDIO';
      case NivelRendimiento.alto:
        return 'ALTO';
    }
  }
}

// Widget para mostrar etiqueta de predicción
class PredictionLabelWidget extends StatelessWidget {
  final Map<String, dynamic>? prediccion;
  final EdgeInsetsGeometry? padding;

  const PredictionLabelWidget({
    Key? key,
    required this.prediccion,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (prediccion == null) {
      return const SizedBox.shrink();
    }

    final nivel = NivelRendimiento.values.firstWhere(
      (e) => e.toString().split('.').last == prediccion!['nivel'],
      orElse: () => NivelRendimiento.medio,
    );

    final color = _getColorForNivel(nivel);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'Predicción: ${_getNivelTexto(nivel)}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForNivel(NivelRendimiento nivel) {
    switch (nivel) {
      case NivelRendimiento.bajo:
        return Colors.red;
      case NivelRendimiento.medio:
        return Colors.amber;
      case NivelRendimiento.alto:
        return Colors.green;
    }
  }

  String _getNivelTexto(NivelRendimiento nivel) {
    switch (nivel) {
      case NivelRendimiento.bajo:
        return 'Bajo';
      case NivelRendimiento.medio:
        return 'Medio';
      case NivelRendimiento.alto:
        return 'Alto';
    }
  }
}