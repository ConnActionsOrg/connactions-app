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

  test('toJson manda a origem só quando existe, uma chave por origem', () {
    const daIdeia = Proposta(
      titulo: 'Pizza',
      formato: FormatoDeAtividade.grupo,
      publica: true,
      origemIdeiaId: 'i1',
    );
    expect(daIdeia.toJson()['origem_ideia_id'], 'i1');
    expect(daIdeia.toJson().containsKey('origem_atividade_id'), isFalse);

    const daComunidade = Proposta(
      titulo: 'Pizza',
      formato: FormatoDeAtividade.grupo,
      publica: true,
      origemAtividadeId: 'a1',
    );
    expect(daComunidade.toJson()['origem_atividade_id'], 'a1');
    expect(daComunidade.toJson().containsKey('origem_ideia_id'), isFalse);

    const doZero = Proposta(
      titulo: 'Pizza',
      formato: FormatoDeAtividade.grupo,
      publica: true,
    );
    expect(doZero.toJson().keys, isNot(contains('origem_ideia_id')));
    expect(doZero.toJson().keys, isNot(contains('origem_atividade_id')));
  });
}
