import 'package:flutter/material.dart';

class CardContainerWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? customShadows;

  const CardContainerWidget({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
    this.customShadows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultElevation = elevation ?? (isDarkMode ? 4 : 2);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(12);
    final defaultPadding = padding ?? const EdgeInsets.all(16.0);

    // Convertir BorderRadiusGeometry a BorderRadius para InkWell
    final inkwellBorderRadius = defaultBorderRadius is BorderRadius 
        ? defaultBorderRadius as BorderRadius
        : BorderRadius.circular(12);

    Widget cardWidget = Container(
      margin: margin,
      padding: defaultPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: defaultBorderRadius,
        boxShadow: customShadows ?? [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: defaultElevation.toDouble(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: inkwellBorderRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

// Widget especializado para tarjetas de estudiantes
class StudentCardWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const StudentCardWidget({
    Key? key,
    required this.child,
    this.onTap,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CardContainerWidget(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: child,
    );
  }
}