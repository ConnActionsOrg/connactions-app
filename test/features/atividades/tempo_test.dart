import 'package:connactions_app/features/atividades/tempo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final agora = DateTime.utc(2026, 9, 29, 12);

  test('tempoRestante em tabela', () {
    final casos = {
      const Duration(days: 2, hours: 4): '2 dias e 4 horas',
      const Duration(days: 1, hours: 3): '1 dia e 3 horas',
      const Duration(days: 3): '3 dias',
      const Duration(days: 1): '1 dia',
      const Duration(hours: 5, minutes: 30): '5 horas',
      const Duration(hours: 1): '1 hora',
      const Duration(minutes: 40): '40 minutos',
      const Duration(minutes: 1, seconds: 10): '1 minuto',
      const Duration(seconds: 20): '1 minuto',
      Duration.zero: 'Prazo venceu',
      const Duration(hours: -3): 'Prazo venceu',
    };
    casos.forEach((resta, texto) {
      expect(tempoRestante(agora.add(resta), agora), texto, reason: '$resta');
    });
  });

  test('haQuantoTempo em tabela', () {
    final casos = {
      const Duration(seconds: 30): 'agora',
      const Duration(minutes: 5): 'há 5 min',
      const Duration(hours: 2, minutes: 10): 'há 2 h',
      const Duration(days: 1, hours: 2): 'há 1 dia',
      const Duration(days: 3): 'há 3 dias',
    };
    casos.forEach((passou, texto) {
      expect(
        haQuantoTempo(agora.subtract(passou), agora),
        texto,
        reason: '$passou',
      );
    });
  });
}
