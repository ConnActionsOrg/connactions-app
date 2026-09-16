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
}
