import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/features/diario/diario.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/autenticador_falso.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/preferencias_em_memoria.dart';
import '../../apoio/seletor_de_foto_falso.dart';

ProviderContainer montar(FakeApi api) {
  final container = ProviderContainer.test(
    overrides: [
      autenticadorProvider.overrideWithValue(
        AutenticadorFalso(conta: contaDeTeste),
      ),
      apiProvider.overrideWithValue(api),
      preferenciasProvider.overrideWithValue(PreferenciasEmMemoria()),
      compartilhadorProvider.overrideWithValue(CompartilhadorFalso()),
      seletorDeFotoProvider.overrideWithValue(SeletorDeFotoFalso()),
    ],
  );
  container.listen(diarioProvider('turma-1'), (_, _) {});
  return container;
}

void main() {
  test('primeira página e carregar mais até o fim', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          for (var i = 1; i <= 25; i++)
            atividadeDeTeste(
              id: 'ativ-$i',
              numero: 26 - i,
              encerradaEm: DateTime.utc(2026, 9, 30),
            ),
        ],
      },
    );
    final c = montar(api);

    final primeira = await c.read(diarioProvider('turma-1').future);
    expect(primeira.itens.length, 20);
    expect(primeira.proximo, '20');
    expect(api.chamadas.last, 'listarDiario:turma-1:');

    await c.read(diarioProvider('turma-1').notifier).carregarMais();
    final tudo = c.read(diarioProvider('turma-1')).value!;
    expect(tudo.itens.length, 25);
    expect(tudo.itens.first.id, 'ativ-1');
    expect(tudo.itens.last.id, 'ativ-25');
    expect(tudo.proximo, isNull);
    expect(api.chamadas.last, 'listarDiario:turma-1:20');

    await c
        .read(diarioProvider('turma-1').notifier)
        .carregarMais(); // no fim, não chama
    expect(api.chamadas.where((c) => c.startsWith('listarDiario')).length, 2);
  });

  test('diário vazio', () async {
    final c = montar(FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]));
    final p = await c.read(diarioProvider('turma-1').future);
    expect(p.itens, isEmpty);
    expect(p.proximo, isNull);
  });
}
