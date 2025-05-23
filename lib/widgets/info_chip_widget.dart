import 'package:flutter/material.dart';

class InfoChipWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final Color? backgroundColor;
  final double? iconSize;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const InfoChipWidget({
    Key? key,
    required this.icon,
    required this.text,
    this.color,
    this.backgroundColor,
    this.iconSize = 14,
    this.fontSize = 12,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = color ?? Theme.of(context).iconTheme.color?.withOpacity(0.7);
    final defaultBackgroundColor = backgroundColor ?? 
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(isDarkMode ? 0.3 : 0.5);

    Widget child = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: defaultBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: defaultColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
                color: defaultColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      child = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    }

    return child;
  }
}