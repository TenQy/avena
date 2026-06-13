String formatMoney(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

String formatCashDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final hour = hour12.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';

  return '$day/$month/$year $hour:$minute $period';
}
