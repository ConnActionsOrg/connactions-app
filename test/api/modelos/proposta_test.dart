import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/proposta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson manda só o que existe e o prazo em UTC', () {
    const minima = Proposta(
      titulo: 'Piquenique',
      formato: FormatoDeAtividade.grupo,
      publica: false,
    );
    expect(minima.toJson(), {
      'titulo': 'Piquenique',
      'descricao': '',
      'formato': 'grupo',
      'publica': false,
    });

    final completa = Proposta(
      titulo: 'Piquenique',
      descricao: 'Cada um leva algo.',
      regras: const ['Um item por pessoa'],
      formato: FormatoDeAtividade.individual,
      publica: true,
      prazo: DateTime(2026, 10, 2, 23, 59, 59), // local
    );
    final json = completa.toJson();
    expect(json['regras'], ['Um item por pessoa']);
    expect(json['formato'], 'individual');
    expect(
      json['prazo'],
      DateTime(2026, 10, 2, 23, 59, 59).toUtc().toIso8601String(),
    );
  });
}
