import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/api/modelos/pagina_do_diario.dart';
import 'package:connactions_app/api/modelos/reacao.dart';
import 'package:connactions_app/features/diario/diario.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/container_de_teste.dart';
import '../../apoio/fake_api.dart';

const coracaoDeOutra = Reacao(
  tipo: TipoDeReacao.coracao,
  total: 1,
  minha: false,
);

/// Faz falhar `reagir` de um tipo só e segura cada tipo até o teste liberar: prova a ordem em que as
/// respostas chegam sem depender de timing.
class _ApiComReacoesSeguradas extends FakeApi {
  _ApiComReacoesSeguradas({
    super.eu,
    super.turmas,
    super.diarioPor,
    this.falhaNoTipo,
  });

  final TipoDeReacao? falhaNoTipo;
  final seguradas = <TipoDeReacao, Completer<void>>{};

  @override
  Future<List<Reacao>> reagir(String atividadeId, TipoDeReacao tipo) async {
    await seguradas[tipo]?.future;
    if (tipo == falhaNoTipo) throw const ErroDeRede('caiu');
    return super.reagir(atividadeId, tipo);
  }
}

/// Segura `listarDiario` quando o teste pede, para manter um build em voo.
class _ApiComDiarioSegurado extends FakeApi {
  _ApiComDiarioSegurado({super.eu, super.turmas, super.diarioPor});

  Completer<void>? segurarDiario;

  @override
  Future<PaginaDoDiario> listarDiario(
    String turmaId, {
    String? apos,
    int limite = 20,
  }) async {
    await segurarDiario?.future;
    return super.listarDiario(turmaId, apos: apos, limite: limite);
  }
}

FakeApi apiCom({List<Reacao> reacoes = const [], int comentarios = 0}) =>
    FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          atividadeDeTeste(id: 'a1', encerradaEm: DateTime.utc(2026, 9, 30)),
        ],
      },
      reacoesPor: {'a1': reacoes},
      comentariosPor: {
        'a1': [
          for (var i = 0; i < comentarios; i++) comentarioDeTeste(id: 'c$i'),
        ],
      },
    );

ProviderContainer montar(FakeApi api) {
  final c = containerDeTeste(api);
  c.listen(diarioProvider('turma-1'), (_, _) {});
  return c;
}

ItemDoDiario item(ProviderContainer c) =>
    c.read(diarioProvider('turma-1')).requireValue.itens.single;

Diario notifier(ProviderContainer c) =>
    c.read(diarioProvider('turma-1').notifier);

void main() {
  test(
    'marcar muda o cartão na hora e a resposta da API assenta o resumo',
    () async {
      final api = apiCom(reacoes: [coracaoDeOutra]);
      api.segurarReagir = Completer<void>();
      final c = montar(api);
      await c.read(diarioProvider('turma-1').future);

      final toque = notifier(c).alternarReacao('a1', TipoDeReacao.coracao);
      await pumpEventQueue();

      // com a API ainda presa, o cartão já mostra o meu coração somado ao da outra pessoa
      expect(item(c).reacoes, const [
        Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true),
      ]);
      expect(api.chamadas, contains('reagir:a1:coracao'));

      // enquanto a chamada estava no ar, mais uma pessoa reagiu: o servidor é quem manda
      api.reacoesPor['a1'] = [
        const Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: false),
      ];
      api.segurarReagir!.complete();
      await toque;

      expect(item(c).reacoes, const [
        Reacao(tipo: TipoDeReacao.coracao, total: 3, minha: true),
      ]);
    },
  );

  test('desmarcar chama desreagir e o tipo some quando era só o meu', () async {
    final api = apiCom(
      reacoes: [const Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: true)],
    );
    final c = montar(api);
    await c.read(diarioProvider('turma-1').future);

    await notifier(c).alternarReacao('a1', TipoDeReacao.fogo);

    expect(api.chamadas, contains('desreagir:a1:fogo'));
    expect(api.chamadas, isNot(contains('reagir:a1:fogo')));
    expect(item(c).reacoes, isEmpty);
  });

  test('se a chamada falha, o cartão volta ao que era e o erro sobe', () async {
    final api = apiCom(reacoes: [coracaoDeOutra]);
    api.falhaAoReagir = const ErroDeRede('caiu');
    final c = montar(api);
    await c.read(diarioProvider('turma-1').future);

    await expectLater(
      notifier(c).alternarReacao('a1', TipoDeReacao.coracao),
      throwsA(isA<ErroDeRede>()),
    );

    expect(item(c).reacoes, const [coracaoDeOutra]);
  });

  test('a falha de um chip não desfaz o outro que ainda está em voo', () async {
    final api = _ApiComReacoesSeguradas(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          atividadeDeTeste(id: 'a1', encerradaEm: DateTime.utc(2026, 9, 30)),
        ],
      },
      falhaNoTipo: TipoDeReacao.fogo,
    );
    api.seguradas[TipoDeReacao.coracao] = Completer<void>();
    final c = montar(api);
    await c.read(diarioProvider('turma-1').future);

    final coracao = notifier(c).alternarReacao('a1', TipoDeReacao.coracao);
    final fogo = notifier(c).alternarReacao('a1', TipoDeReacao.fogo);
    await expectLater(fogo, throwsA(isA<ErroDeRede>()));

    // o fogo falhou e voltou; o coração, ainda em voo, continua marcado no cartão
    expect(item(c).reacoes.map((r) => r.tipo), [TipoDeReacao.coracao]);
    expect(item(c).reacoes.single.minha, isTrue);

    api.seguradas[TipoDeReacao.coracao]!.complete();
    await coracao;
    expect(item(c).reacoes.single.tipo, TipoDeReacao.coracao);
  });

  test(
    'toque duplo no mesmo chip é ignorado; chips diferentes seguem',
    () async {
      final api = apiCom();
      api.segurarReagir = Completer<void>();
      final c = montar(api);
      await c.read(diarioProvider('turma-1').future);

      final primeiro = notifier(c).alternarReacao('a1', TipoDeReacao.coracao);
      final repetido = notifier(c).alternarReacao('a1', TipoDeReacao.coracao);
      final outro = notifier(c).alternarReacao('a1', TipoDeReacao.fogo);
      await pumpEventQueue();
      api.segurarReagir!.complete();
      await Future.wait([primeiro, repetido, outro]);

      expect(
        api.chamadas.where((x) => x == 'reagir:a1:coracao'),
        hasLength(1),
        reason: 'o segundo toque no coração não pode virar outra chamada',
      );
      expect(
        api.chamadas,
        isNot(contains('desreagir:a1:coracao')),
        reason:
            'o segundo toque, sem a trava, leria o cartão marcado e desmarcaria',
      );
      expect(api.chamadas, contains('reagir:a1:fogo'));
      expect(item(c).reacoes.map((r) => r.tipo), [
        TipoDeReacao.coracao,
        TipoDeReacao.fogo,
      ]);
    },
  );

  test(
    'depois que a chamada termina, o mesmo chip volta a responder',
    () async {
      final api = apiCom();
      final c = montar(api);
      await c.read(diarioProvider('turma-1').future);

      await notifier(c).alternarReacao('a1', TipoDeReacao.festa);
      await notifier(c).alternarReacao('a1', TipoDeReacao.festa);

      expect(
        api.chamadas,
        containsAllInOrder(['reagir:a1:festa', 'desreagir:a1:festa']),
      );
      expect(item(c).reacoes, isEmpty);
    },
  );

  group('provider descartado com a chamada em voo', () {
    // Tira o único ouvinte (a tela saiu) e espera o autoDispose agir.
    Future<({Future<void> toque})> soltarComChamadaSegura(FakeApi api) async {
      final c = containerDeTeste(api);
      final ouvinte = c.listen(diarioProvider('turma-1'), (_, _) {});
      await c.read(diarioProvider('turma-1').future);
      final n = c.read(diarioProvider('turma-1').notifier);
      final toque = n.alternarReacao('a1', TipoDeReacao.coracao);
      await pumpEventQueue();
      ouvinte.close();
      await pumpEventQueue();
      expect(
        c.exists(diarioProvider('turma-1')),
        isFalse,
        reason: 'o provider tem de ter morrido',
      );
      return (toque: toque); // num record: await direto achataria o Future
    }

    test('a resposta de sucesso depois do descarte não lança', () async {
      final api = apiCom();
      api.segurarReagir = Completer<void>();
      final emVoo = await soltarComChamadaSegura(api);

      api.segurarReagir!.complete();
      await expectLater(emVoo.toque, completes);
    });

    test(
      'a falha depois do descarte sobe o erro da API, não o do ref',
      () async {
        final api = apiCom();
        api.segurarReagir = Completer<void>();
        api.falhaAoReagir = const ErroDeRede('caiu');
        final emVoo = await soltarComChamadaSegura(api);

        api.segurarReagir!.complete();
        await expectLater(emVoo.toque, throwsA(isA<ErroDeRede>()));
      },
    );
  });

  test('provider descartado enquanto espera o build não chama a API', () async {
    final api = _ApiComDiarioSegurado(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          atividadeDeTeste(id: 'a1', encerradaEm: DateTime.utc(2026, 9, 30)),
        ],
      },
    );
    final c = containerDeTeste(api);
    final ouvinte = c.listen(diarioProvider('turma-1'), (_, _) {});
    await c.read(diarioProvider('turma-1').future);
    final n = c.read(diarioProvider('turma-1').notifier);

    api.segurarDiario = Completer<void>();
    c.invalidate(diarioProvider('turma-1')); // recarga em voo
    await pumpEventQueue();
    final toque = n.alternarReacao('a1', TipoDeReacao.coracao);
    await pumpEventQueue();
    ouvinte.close();
    await pumpEventQueue();

    api.segurarDiario!.complete();
    await pumpEventQueue();
    await expectLater(toque, completes);
    expect(api.chamadas.where((x) => x.startsWith('reagir')), isEmpty);
  });

  test('atividade que não está na página não chama a API', () async {
    final api = apiCom();
    final c = montar(api);
    await c.read(diarioProvider('turma-1').future);

    await notifier(c).alternarReacao('nao-esta-aqui', TipoDeReacao.coracao);

    expect(api.chamadas.where((x) => x.startsWith('reagir')), isEmpty);
  });

  test('ajustarComentarios soma e subtrai, sem passar de zero', () async {
    final c = montar(apiCom(comentarios: 1));
    await c.read(diarioProvider('turma-1').future);

    notifier(c).ajustarComentarios('a1', 1);
    expect(item(c).totalDeComentarios, 2);
    notifier(c).ajustarComentarios('a1', -1);
    notifier(c).ajustarComentarios('a1', -1);
    notifier(c).ajustarComentarios('a1', -1);
    expect(item(c).totalDeComentarios, 0);
    notifier(c).ajustarComentarios('nao-esta-aqui', 1); // não estoura
  });

  test('trocarCapa troca só a capa; os itens e o cursor ficam', () async {
    final c = montar(apiCom());
    await c.read(diarioProvider('turma-1').future);
    final antes = c.read(diarioProvider('turma-1')).requireValue;

    notifier(c).trocarCapa(
      capaDeTeste(titulo: 'Meu diário', paleta: PaletaDoDiario.ambar),
    );

    final depois = c.read(diarioProvider('turma-1')).requireValue;
    expect(depois.capa!.titulo, 'Meu diário');
    expect(depois.capa!.paleta, PaletaDoDiario.ambar);
    expect(depois.itens, same(antes.itens));
    expect(depois.proximo, antes.proximo);
  });

  test('carregar mais mantém a capa da primeira página', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          for (var i = 1; i <= 25; i++)
            atividadeDeTeste(id: 'a$i', encerradaEm: DateTime.utc(2026, 9, 30)),
        ],
      },
      capaPor: {'turma-1': capaDeTeste(titulo: 'Noites de quinta')},
    );
    final c = montar(api);
    final primeira = await c.read(diarioProvider('turma-1').future);
    expect(primeira.capa!.titulo, 'Noites de quinta');

    await notifier(c).carregarMais();

    final tudo = c.read(diarioProvider('turma-1')).requireValue;
    expect(tudo.itens, hasLength(25));
    expect(tudo.capa!.titulo, 'Noites de quinta');
    expect(tudo.capa!.atividades, 25);
  });
}
