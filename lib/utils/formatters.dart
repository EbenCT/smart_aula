import 'package:intl/intl.dart';
import '../config/constants.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }
  
  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }
  
  static String getMonthYearFormat(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
  
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return 'Hace ${(difference.inDays / 365).floor()} año(s)';
    } else if (difference.inDays > 30) {
      return 'Hace ${(difference.inDays / 30).floor()} mes(es)';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día(s)';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora(s)';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto(s)';
    } else {
      return 'Justo ahora';
    }
  }
}

class NumberFormatter {
  static String formatDecimal(double number, {int decimals = 1}) {
    return number.toStringAsFixed(decimals);
  }
  
  static String formatPercentage(double number, {int decimals = 0}) {
    return '${formatDecimal(number, decimals: decimals)}%';
  }
  
  static String formatCurrency(double number) {
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(number);
  }
}