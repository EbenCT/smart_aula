// lib/widgets/sesion_status_widget.dart
import 'package:flutter/material.dart';

class SesionStatusWidget extends StatelessWidget {
  final bool hasSesionActiva;
  final String? nombreSesion;
  final int? estudiantesPresentes;
  final VoidCallback? onCerrarSesion; // Cambiamos de onVerDetalles a onCerrarSesion

  const SesionStatusWidget({
    Key? key,
    required this.hasSesionActiva,
    this.nombreSesion,
    this.estudiantesPresentes,
    this.onCerrarSesion, // Actualizado el nombre del callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!hasSesionActiva) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión GPS Activa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 12,
                  ),
                ),
                if (nombreSesion != null)
                  Text(
                    nombreSesion!,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 11,
                    ),
                  ),
                if (estudiantesPresentes != null)
                  Text(
                    '$estudiantesPresentes estudiantes han marcado asistencia',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (onCerrarSesion != null)
            TextButton.icon(
              onPressed: onCerrarSesion,
              icon: Icon(
                Icons.stop_circle_outlined,
                color: Colors.red.shade700,
                size: 16,
              ),
              label: Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}