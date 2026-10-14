import 'package:connactions_app/api/erro_da_api.dart';
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
    expect(tudo.itens.first.atividade.id, 'ativ-1');
    expect(tudo.itens.last.atividade.id, 'ativ-25');
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

  group('depois de uma recarga que falhou', () {
    FakeApi apiComEncerradas(int quantas) => FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          for (var i = 1; i <= quantas; i++)
            atividadeDeTeste(
              id: 'ativ-$i',
              encerradaEm: DateTime.utc(2026, 9, 30),
            ),
        ],
      },
    );

    // Carrega a primeira página e deixa o provider com o erro junto dela, como depois de um
    // "puxar para baixo" sem rede.
    Future<ProviderContainer> comRecargaFalha(FakeApi api) async {
      final c = montar(api);
      await c.read(diarioProvider('turma-1').future);
      api.falhaAoListarDiario = const ErroDeRede('caiu');
      await expectLater(
        c.refresh(diarioProvider('turma-1').future),
        throwsA(isA<ErroDeRede>()),
      );
      api.falhaAoListarDiario = null;
      return c;
    }

    test('carregar mais pagina a partir da página que já estava', () async {
      final api = apiComEncerradas(25);
      final c = await comRecargaFalha(api);

      await c.read(diarioProvider('turma-1').notifier).carregarMais();

      final estado = c.read(diarioProvider('turma-1'));
      expect(estado.hasError, isFalse);
      expect(estado.value!.itens.length, 25);
      expect(estado.value!.proximo, isNull);
      expect(api.chamadas.last, 'listarDiario:turma-1:20');
    });

    test('carregar mais com outra recarga em voo espera por ela', () async {
      final api = apiComEncerradas(25);
      final c = await comRecargaFalha(api);
      // encerrada por outra pessoa enquanto a rede estava fora
      api.diarioPor['turma-1']!.insert(
        0,
        atividadeDeTeste(id: 'ativ-nova', encerradaEm: DateTime.utc(2026, 10)),
      );

      // sem await entre as duas: a recarga ainda está em voo quando o carregarMais começa
      final recarga = c.refresh(diarioProvider('turma-1').future);
      final mais = c.read(diarioProvider('turma-1').notifier).carregarMais();
      await Future.wait([recarga, mais]);

      final ids = [
        for (final i in c.read(diarioProvider('turma-1')).value!.itens)
          i.atividade.id,
      ];
      expect(ids.first, 'ativ-nova');
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, hasLength(26));
    });
  });
}
