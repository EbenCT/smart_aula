// lib/widgets/date_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectorWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final String label;
  final bool localeInitialized;

  const DateSelectorWidget({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
    this.label = 'Fecha de clase',
    this.localeInitialized = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    if (localeInitialized) {
      return DateFormat('EEEE, dd MMMM yyyy', 'es').format(selectedDate);
    } else {
      return DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.white,
                    surface: Theme.of(context).cardColor,
                    onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  )
                : ColorScheme.light(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null && fechaSeleccionada != selectedDate) {
      onDateChanged(fechaSeleccionada);
    }
  }
}