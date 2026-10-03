import 'package:connactions_app/app/preferencias.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/preferencias_em_memoria.dart';

void main() {
  test('lê nulo, grava, relê e apaga', () async {
    final prefs = PreferenciasEmMemoria();
    expect(prefs.ler(ChaveDePreferencia.turmaAtivaId), isNull);

    await prefs.gravar(ChaveDePreferencia.turmaAtivaId, 'turma-2');
    expect(prefs.ler(ChaveDePreferencia.turmaAtivaId), 'turma-2');

    await prefs.apagar(ChaveDePreferencia.turmaAtivaId);
    expect(prefs.ler(ChaveDePreferencia.turmaAtivaId), isNull);
  });

  test('nasce com os valores iniciais', () {
    final prefs = PreferenciasEmMemoria({ChaveDePreferencia.turmaAtivaId: 'x'});
    expect(prefs.ler('turma_ativa_id'), 'x');
  });

  test('todas as chaves estão no allowList', () {
    // fora dele o SharedPreferencesWithCache recusa a gravação, e só no aparelho
    expect(
      ChaveDePreferencia.todas,
      containsAll([
        ChaveDePreferencia.turmaAtivaId,
        ChaveDePreferencia.notificacoesPerguntadas,
      ]),
    );
  });

  test('a marca das notificações tem o nome que o aparelho já guarda', () {
    expect(
      ChaveDePreferencia.notificacoesPerguntadas,
      'notificacoes_perguntadas',
    );
  });
}
