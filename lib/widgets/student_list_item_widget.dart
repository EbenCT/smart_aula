// lib/widgets/student_list_item_widget.dart
import 'package:flutter/material.dart';
import '../models/estudiante.dart';
import 'avatar_widget.dart';
import 'card_container_widget.dart';

class StudentListItemWidget extends StatelessWidget {
  final Estudiante estudiante;
  final Widget? trailingWidget;
  final Widget? bottomWidget;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const StudentListItemWidget({
    Key? key,
    required this.estudiante,
    this.trailingWidget,
    this.bottomWidget,
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
          // Fila principal con avatar, información y widget trailing
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AvatarWidget(
                nombre: estudiante.nombre,
                apellido: estudiante.apellido,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estudiante.nombreCompleto,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${estudiante.codigo}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget!,
              ],
            ],
          ),
          
          // Widget adicional en la parte inferior
          if (bottomWidget != null) ...[
            const SizedBox(height: 16),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}