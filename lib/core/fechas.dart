import 'package:intl/intl.dart';

/// Las citas son en Cúcuta: se muestran y se piden siempre en hora de Colombia
/// (UTC−5, sin horario de verano), sin importar la zona horaria del teléfono.
const _desfaseColombia = Duration(hours: -5);

/// El mismo instante, con los campos (día, hora…) de la hora de Colombia.
/// Solo sirve para mostrar o comparar fechas de calendario.
DateTime enColombia(DateTime instante) =>
    instante.toUtc().add(_desfaseColombia);

DateTime ahoraEnColombia() => enColombia(DateTime.now());

/// Fecha y hora elegidas en el calendario (hora de Colombia) en el formato de la
/// API: `2026-10-20T15:00:00-05:00`.
String isoColombia(DateTime fecha, int hora, int minuto) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}'
      'T${dos(hora)}:${dos(minuto)}:00-05:00';
}

final _dia = DateFormat("EEEE d 'de' MMMM", 'es');
final _hora = DateFormat('h:mm a', 'es');

/// "jueves 15 de octubre".
String formatoDia(DateTime instante) => _dia.format(enColombia(instante));

/// "3:00 p. m.". `intl` separa "p. m." con espacios especiales; se usan
/// espacios normales para que el texto sea predecible.
String formatoHora(DateTime instante) => _hora
    .format(enColombia(instante))
    .replaceAll(RegExp('[\u00a0\u202f]'), ' ');

/// "jueves 15 de octubre, 3:00 p. m.".
String formatoFechaHora(DateTime instante) =>
    '${formatoDia(instante)}, ${formatoHora(instante)}';

/// Día elegido en el calendario (ya es fecha de Colombia): "jueves 15 de octubre".
String formatoDiaCalendario(DateTime fecha) => _dia.format(fecha);
