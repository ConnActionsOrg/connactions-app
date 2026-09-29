import 'dart:math' as math;

/// "2 dias e 4 horas", "5 horas", "40 minutos" ou "Prazo venceu". Abaixo de um minuto ainda
/// conta como "1 minuto": o prazo não venceu.
String tempoRestante(DateTime prazo, DateTime agora) {
  final resta = prazo.difference(agora);
  if (resta <= Duration.zero) return 'Prazo venceu';
  if (resta < const Duration(hours: 1)) {
    return _plural(math.max(1, resta.inMinutes), 'minuto', 'minutos');
  }
  if (resta < const Duration(days: 1)) {
    return _plural(resta.inHours, 'hora', 'horas');
  }
  final dias = resta.inDays;
  final horas = resta.inHours - dias * 24;
  final textoDias = _plural(dias, 'dia', 'dias');
  if (horas == 0) return textoDias;
  return '$textoDias e ${_plural(horas, 'hora', 'horas')}';
}

/// "agora", "há 5 min", "há 2 h", "há 3 dias".
String haQuantoTempo(DateTime instante, DateTime agora) {
  final passou = agora.difference(instante);
  if (passou < const Duration(minutes: 1)) return 'agora';
  if (passou < const Duration(hours: 1)) return 'há ${passou.inMinutes} min';
  if (passou < const Duration(days: 1)) return 'há ${passou.inHours} h';
  return 'há ${_plural(passou.inDays, 'dia', 'dias')}';
}

String _plural(int n, String um, String varios) =>
    n == 1 ? '1 $um' : '$n $varios';
