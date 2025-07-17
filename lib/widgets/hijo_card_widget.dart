import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/estudiante.dart';
import 'card_container_widget.dart';
import 'avatar_widget.dart';

class HijoCardWidget extends StatelessWidget {
  final Estudiante hijo;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const HijoCardWidget({
    Key? key,
    required this.hijo,
    this.onTap,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CardContainerWidget(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila principal con avatar e información
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar del hijo
              AvatarWidget(
                nombre: hijo.nombre,
                apellido: hijo.apellido,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              
              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre completo
                    Text(
                      hijo.nombreCompleto,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Información adicional
                    _buildInfoChip(
                      context,
                      icon: Icons.cake_outlined,
                      label: 'Nacimiento',
                      value: DateFormat('dd/MM/yyyy').format(hijo.fechaNacimiento),
                    ),
                    const SizedBox(height: 6),
                    
                    _buildInfoChip(
                      context,
                      icon: Icons.person_outline,
                      label: 'Género',
                      value: hijo.genero,
                    ),
                    const SizedBox(height: 6),
                    
                    _buildInfoChip(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'Edad',
                      value: '${_calcularEdad(hijo.fechaNacimiento)} años',
                    ),
                  ],
                ),
              ),
              
              // Indicador de navegación
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Información de contacto si está disponible
          if (hijo.email.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hijo.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  int _calcularEdad(DateTime fechaNacimiento) {
    final now = DateTime.now();
    int edad = now.year - fechaNacimiento.year;
    
    if (now.month < fechaNacimiento.month ||
        (now.month == fechaNacimiento.month && now.day < fechaNacimiento.day)) {
      edad--;
    }
    
    return edad;
  }
}