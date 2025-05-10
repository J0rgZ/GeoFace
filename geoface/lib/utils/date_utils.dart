// utils/date_utils.dart
import 'package:intl/intl.dart';

// Verifica si dos fechas son el mismo día
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && 
         date1.month == date2.month && 
         date1.day == date2.day;
}

// Formatea la fecha en formato día/mes/año
String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

// Formatea la hora en formato hora:minutos
String formatTime(DateTime date) {
  return DateFormat('HH:mm').format(date);
}

// Calcula la duración entre dos fechas en formato "hh:mm"
String calculateDuration(DateTime start, DateTime? end) {
  if (end == null) return "--:--";
  
  final diff = end.difference(start);
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

// Devuelve el primer día del mes actual
DateTime firstDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

// Devuelve el último día del mes actual
DateTime lastDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0);
}

// Obtiene el inicio de la semana (lunes) para una fecha dada
DateTime startOfWeek(DateTime date) {
  int difference = date.weekday - 1;
  return date.subtract(Duration(days: difference));
}