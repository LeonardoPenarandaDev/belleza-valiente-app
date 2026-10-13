import 'package:intl/intl.dart';

// Miles con punto, como se escriben los precios en Colombia.
final _miles = NumberFormat('#,##0', 'es_CO');

/// 25000 → "$25.000".
String formatoPesos(int valor) => '\$${_miles.format(valor)}';

/// 45 → "45 min", 90 → "1 h 30 min", 120 → "2 h".
String formatoDuracion(int minutos) {
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '$resto min';
  if (resto == 0) return '$horas h';
  return '$horas h $resto min';
}
