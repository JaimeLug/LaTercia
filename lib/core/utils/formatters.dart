import 'package:intl/intl.dart';

String formatCurrency(double amount, String symbol, {int decimals = 2}) {
  final formatted = amount.toStringAsFixed(decimals);
  return '$symbol$formatted';
}

String formatOrderNumber(int id) => '#${id.toString().padLeft(4, '0')}';

String formatDateTime(DateTime dt) {
  return DateFormat("d MMM yyyy, HH:mm", 'es_MX').format(dt);
}

String formatDate(DateTime dt) {
  return DateFormat("d MMM yyyy", 'es_MX').format(dt);
}

String formatTime(DateTime dt) {
  return DateFormat("HH:mm", 'es_MX').format(dt);
}

String formatElapsed(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
}
