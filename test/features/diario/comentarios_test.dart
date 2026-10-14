import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/features/diario/comentarios.dart';
import 'package:connactions_app/features/diario/diario.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/container_de_teste.dart';
import '../../apoio/fake_api.dart';

const alvo = (turmaId: 'turma-1', atividadeId: 'a1');

FakeApi apiCom({int comentarios = 0}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  diarioPor: {
    'turma-1': [
      atividadeDeTeste(id: 'a1', encerradaEm: DateTime.utc(2026, 9, 30)),
    ],
  },
  comentariosPor: {
    'a1': [
      for (var i = 1; i <= comentarios; i++)
        comentarioDeTeste(id: 'c$i', texto: 'Comentário $i'),
    ],
  },
);

/// O Diário fica ouvido junto: é onde o total do cartão mora.
ProviderContainer montar(FakeApi api) {
  final c = containerDeTeste(api);
  c.listen(diarioProvider('turma-1'), (_, _) {});
  c.listen(comentariosProvider(alvo), (_, _) {});
  return c;
}

Comentarios notifier(ProviderContainer c) =>
    c.read(comentariosProvider(alvo).notifier);

int totalDoCartao(ProviderContainer c) => c
    .read(diarioProvider('turma-1'))
    .requireValue
    .itens
    .single
    .totalDeComentarios;

List<String> ids(ProviderContainer c) => [
  for (final x in c.read(comentariosProvider(alvo)).requireValue.itens) x.id,
];

void main() {
  test('primeira página e carregar mais até o fim', () async {
    final api = apiCom(comentarios: 60);
    final c = montar(api);

    final primeira = await c.read(comentariosProvider(alvo).future);
    expect(primeira.itens, hasLength(50));
    expect(primeira.proximo, '50');
    expect(api.chamadas, contains('listarComentarios:a1:'));

    await notifier(c).carregarMais();
    expect(ids(c), hasLength(60));
    expect(ids(c).first, 'c1');
    expect(ids(c).last, 'c60');
    expect(c.read(comentariosProvider(alvo)).requireValue.proximo, isNull);

    await notifier(c).carregarMais(); // no fim, não chama
    expect(
      api.chamadas.where((x) => x.startsWith('listarComentarios')),
      hasLength(2),
    );
  });

  test(
    'comentar põe o meu no fim da lista e soma ao cartão do Diário',
    () async {
      final c = montar(apiCom(comentarios: 2));
      await c.read(comentariosProvider(alvo).future);
      await c.read(diarioProvider('turma-1').future);
      expect(totalDoCartao(c), 2);

      await notifier(c).comentar('  Foi demais!  ');

      expect(ids(c), ['c1', 'c2', 'com-1']);
      final meu = c.read(comentariosProvider(alvo)).requireValue.itens.last;
      expect(meu.texto, 'Foi demais!');
      expect(meu.meu, isTrue);
      expect(totalDoCartao(c), 3);
    },
  );

  test(
    'com páginas por carregar, o novo não entra no meio: só o total sobe',
    () async {
      final c = montar(apiCom(comentarios: 60));
      await c.read(comentariosProvider(alvo).future); // só os 50 primeiros
      await c.read(diarioProvider('turma-1').future);

      await notifier(c).comentar('Mais um');

      expect(ids(c), hasLength(50));
      expect(ids(c), isNot(contains('com-1')));
      expect(totalDoCartao(c), 61);
      // quando a lista chegar ao fim, ele aparece, no lugar certo
      await notifier(c).carregarMais();
      expect(ids(c).last, 'com-1');
    },
  );

  test('apagar tira da lista e subtrai do cartão', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          atividadeDeTeste(id: 'a1', encerradaEm: DateTime.utc(2026, 9, 30)),
        ],
      },
      comentariosPor: {
        'a1': [
          comentarioDeTeste(id: 'alheio'),
          comentarioDeTeste(id: 'meu', meu: true),
        ],
      },
    );
    final c = montar(api);
    await c.read(comentariosProvider(alvo).future);
    await c.read(diarioProvider('turma-1').future);

    await notifier(c).apagar('meu');

    expect(ids(c), ['alheio']);
    expect(totalDoCartao(c), 1);
    expect(api.chamadas, contains('apagarComentario:meu'));
  });

  test(
    'falha ao comentar ou apagar sobe o erro e não mexe na lista nem no total',
    () async {
      final api = apiCom(comentarios: 1);
      final c = montar(api);
      await c.read(comentariosProvider(alvo).future);
      await c.read(diarioProvider('turma-1').future);

      api.falhaAoComentar = const ErroDeRede('caiu');
      await expectLater(notifier(c).comentar('oi'), throwsA(isA<ErroDeRede>()));
      api.falhaAoApagarComentario = const ErroDeRede('caiu');
      await expectLater(notifier(c).apagar('c1'), throwsA(isA<ErroDeRede>()));

      expect(ids(c), ['c1']);
      expect(totalDoCartao(c), 1);
    },
  );

  test(
    'texto que a API recusa (vazio) sobe como ErroDaApi e não vira comentário',
    () async {
      final c = montar(apiCom());
      await c.read(comentariosProvider(alvo).future);
      await c.read(diarioProvider('turma-1').future);

      await expectLater(
        notifier(c).comentar('   '),
        throwsA(isA<ErroDaApi>().having((e) => e.status, 'status', 422)),
      );

      expect(ids(c), isEmpty);
      expect(totalDoCartao(c), 0);
    },
  );
}
