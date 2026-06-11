// Formato corto de fecha para UI: dd/mm/aaaa
String formatShortDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return "$d/$m/${date.year}";
}
