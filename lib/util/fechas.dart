/// Fechas en español sin depender de paquetes externos.
library;

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _dias = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

/// "Miércoles 11 de noviembre"
String fechaLarga(DateTime f) {
  final dia = _dias[f.weekday - 1];
  return '${dia[0].toUpperCase()}${dia.substring(1)} ${f.day} de ${_meses[f.month - 1]}';
}

/// "Hoy", "Ayer" o "11 de noviembre".
String fechaRelativa(DateTime f, DateTime ahora) {
  final a = DateTime(ahora.year, ahora.month, ahora.day);
  final b = DateTime(f.year, f.month, f.day);
  final dif = a.difference(b).inDays;
  if (dif == 0) return 'Hoy';
  if (dif == 1) return 'Ayer';
  final anio = f.year == ahora.year ? '' : ' de ${f.year}';
  return '${f.day} de ${_meses[f.month - 1]}$anio';
}

/// "4:05 p. m."
String hora(DateTime f) {
  final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final m = f.minute.toString().padLeft(2, '0');
  return '$h:$m ${f.hour < 12 ? 'a. m.' : 'p. m.'}';
}
