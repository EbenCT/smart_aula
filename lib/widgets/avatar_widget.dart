import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String nombre;
  final String apellido;
  final String? correo;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const AvatarWidget({
    Key? key,
    required this.nombre,
    required this.apellido,
    this.correo,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String initials = _getInitials();
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize ?? _calculateFontSize(),
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }

  String _getInitials() {
    if (nombre.isNotEmpty && apellido.isNotEmpty) {
      return nombre.substring(0, 1).toUpperCase() + 
             apellido.substring(0, 1).toUpperCase();
    } else if (correo != null && correo!.isNotEmpty) {
      return correo!.substring(0, 1).toUpperCase();
    } else {
      return '?';
    }
  }

  double _calculateFontSize() {
    // Calcular tamaño de fuente basado en el radio
    if (radius <= 20) {
      return 14;
    } else if (radius <= 30) {
      return 18;
    } else if (radius <= 40) {
      return 24;
    } else {
      return radius * 0.6;
    }
  }
}