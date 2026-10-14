import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/api/modelos/comentario.dart';
import 'package:connactions_app/api/modelos/reacao.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';

// O FakeApi tem de seguir as regras da API: se ele divergir, os testes de tela passam por um contrato
// que não existe. Aqui cada regra do contrato do Diário aparece uma vez, contra o dublê.

final eu = pessoaDoEu(euDeTeste());

Atividade encerrada(String id, {int fotos = 0}) => atividadeDeTeste(
  id: id,
  encerradaEm: DateTime.utc(2026, 9, 30),
  registros: [for (var i = 0; i < fotos; i++) registroDeTeste(id: '$id-r$i')],
);

FakeApi apiCom({
  List<Atividade>? encerradas,
  Atividade? aberta,
  Map<String, List<Reacao>> reacoesPor = const {},
  Map<String, List<Comentario>> comentariosPor = const {},
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  diarioPor: {
    'turma-1': encerradas ?? [encerrada('a1')],
  },
  abertaPor: {'turma-1': aberta},
  reacoesPor: reacoesPor,
  comentariosPor: comentariosPor,
);

Matcher erroCom(String codigo) =>
    throwsA(isA<ErroDaApi>().having((e) => e.codigo, 'codigo', codigo));

void main() {
  group('reações', () {
    test(
      'reagir marca, repetir não duplica e o resumo sai na ordem fixa',
      () async {
        final api = apiCom();
        // na ordem inversa: o resumo tem de sair na ordem dos tipos, não na da gravação
        for (final tipo in TipoDeReacao.values.reversed) {
          await api.reagir('a1', tipo);
        }
        final resumo = await api.reagir('a1', TipoDeReacao.coracao);

        expect(resumo.map((r) => r.tipo), TipoDeReacao.values);
        expect(resumo.every((r) => r.total == 1 && r.minha), isTrue);
      },
    );

    test(
      'reagir soma à reação de outra pessoa e desreagir só tira a minha',
      () async {
        final api = apiCom(
          reacoesPor: {
            'a1': [
              const Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false),
            ],
          },
        );
        var resumo = await api.reagir('a1', TipoDeReacao.fogo);
        expect(
          resumo.single,
          const Reacao(tipo: TipoDeReacao.fogo, total: 2, minha: true),
        );

        resumo = await api.desreagir('a1', TipoDeReacao.fogo);
        expect(
          resumo.single,
          const Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false),
        );

        // tirar o que não está marcado não é erro e não muda nada
        resumo = await api.desreagir('a1', TipoDeReacao.fogo);
        expect(resumo.single.total, 1);
      },
    );

    test('desreagir a última reação tira o tipo do resumo', () async {
      final api = apiCom();
      await api.reagir('a1', TipoDeReacao.festa);
      expect(await api.desreagir('a1', TipoDeReacao.festa), isEmpty);
    });

    test(
      'na atividade aberta é 409, e em atividade que não existe, 404',
      () async {
        final api = apiCom(aberta: atividadeDeTeste(id: 'aberta'));
        await expectLater(
          api.reagir('aberta', TipoDeReacao.coracao),
          erroCom('atividade_aberta'),
        );
        await expectLater(
          api.reagir('nada', TipoDeReacao.coracao),
          erroCom('nao_encontrado'),
        );
      },
    );
  });

  group('comentários', () {
    test(
      'comentar apara o texto, devolve o meu e vai para o fim da lista',
      () async {
        final api = apiCom();
        final c = await api.comentar('a1', '  Foi demais!  ');

        expect(c.texto, 'Foi demais!');
        expect(c.meu, isTrue);
        expect(c.autor.id, eu.id);
        final pagina = await api.listarComentarios('a1');
        expect(pagina.itens.map((x) => x.id), [c.id]);
      },
    );

    test(
      'vazio, só espaços e mais de 500 caracteres são 422; 500 emojis cabem',
      () async {
        final api = apiCom();
        await expectLater(api.comentar('a1', ''), erroCom('dados_invalidos'));
        await expectLater(
          api.comentar('a1', '   '),
          erroCom('dados_invalidos'),
        );
        await expectLater(
          api.comentar('a1', 'a' * 501),
          erroCom('dados_invalidos'),
        );
        // o teto é em caracteres, não em unidades UTF-16: 500 emojis são 1000 unidades
        await api.comentar('a1', '😀' * 500);
        await expectLater(
          api.comentar('a1', '😀' * 501),
          erroCom('dados_invalidos'),
        );
      },
    );

    test(
      'a lista pagina pelo cursor, do mais antigo para o mais novo',
      () async {
        final api = apiCom(
          comentariosPor: {
            'a1': [
              for (var i = 1; i <= 5; i++)
                comentarioDeTeste(id: 'c$i', texto: 'n$i'),
            ],
          },
        );
        final p1 = await api.listarComentarios('a1', limite: 2);
        expect(p1.itens.map((c) => c.id), ['c1', 'c2']);
        expect(p1.proximo, '2');
        final p3 = await api.listarComentarios('a1', apos: '4', limite: 2);
        expect(p3.itens.map((c) => c.id), ['c5']);
        expect(p3.proximo, isNull);
      },
    );

    test(
      'só o autor apaga o próprio: o alheio é 403 e o que não existe, 404',
      () async {
        final api = apiCom(
          comentariosPor: {
            'a1': [
              comentarioDeTeste(id: 'alheio'),
              comentarioDeTeste(id: 'meu', meu: true),
            ],
          },
        );
        await expectLater(
          api.apagarComentario('alheio'),
          erroCom('sem_acesso'),
        );
        await expectLater(
          api.apagarComentario('nada'),
          erroCom('nao_encontrado'),
        );
        await api.apagarComentario('meu');
        expect((await api.listarComentarios('a1')).itens.map((c) => c.id), [
          'alheio',
        ]);
      },
    );

    test('comentar e listar na atividade aberta é 409', () async {
      final api = apiCom(aberta: atividadeDeTeste(id: 'aberta'));
      await expectLater(
        api.comentar('aberta', 'oi'),
        erroCom('atividade_aberta'),
      );
      await expectLater(
        api.listarComentarios('aberta'),
        erroCom('atividade_aberta'),
      );
    });
  });

  group('capa', () {
    test('sem personalizar é o padrão, com os contadores de agora', () async {
      final api = apiCom(
        encerradas: [encerrada('a1', fotos: 2), encerrada('a2', fotos: 1)],
      );
      final pagina = await api.listarDiario('turma-1');

      final capa = pagina.capa!;
      expect(capa.titulo, isNull);
      expect(capa.frase, isNull);
      expect(capa.paleta, PaletaDoDiario.areia);
      expect(capa.sticker, StickerDoDiario.livro);
      expect(capa.atividades, 2);
      expect(capa.fotos, 3);
    });

    test('só a primeira página traz a capa', () async {
      final api = apiCom(
        encerradas: [for (var i = 1; i <= 25; i++) encerrada('a$i')],
      );
      final primeira = await api.listarDiario('turma-1');
      final segunda = await api.listarDiario('turma-1', apos: primeira.proximo);

      expect(primeira.capa, isNotNull);
      expect(segunda.capa, isNull);
    });

    test('personalizar só mexe no que veio, e vazio volta ao padrão', () async {
      final api = apiCom();
      var capa = await api.personalizarDiario(
        'turma-1',
        const AlteracoesDaCapa(
          titulo: '  Noites de quinta  ',
          frase: 'Pizza',
          paleta: PaletaDoDiario.salvia,
          sticker: StickerDoDiario.pizza,
        ),
      );
      expect(capa.titulo, 'Noites de quinta');

      capa = await api.personalizarDiario(
        'turma-1',
        const AlteracoesDaCapa(sticker: StickerDoDiario.cafe),
      );
      expect(capa.titulo, 'Noites de quinta');
      expect(capa.frase, 'Pizza');
      expect(capa.paleta, PaletaDoDiario.salvia);
      expect(capa.sticker, StickerDoDiario.cafe);

      capa = await api.personalizarDiario(
        'turma-1',
        const AlteracoesDaCapa(titulo: '   '),
      );
      expect(capa.titulo, isNull);
      expect(capa.frase, 'Pizza');
      // e o Diário passa a mostrar o que ficou gravado
      expect(
        (await api.listarDiario('turma-1')).capa!.sticker,
        StickerDoDiario.cafe,
      );
    });

    test(
      'título com mais de 40 e frase com mais de 80 caracteres são 422',
      () async {
        final api = apiCom();
        await expectLater(
          api.personalizarDiario('turma-1', AlteracoesDaCapa(titulo: 'a' * 41)),
          erroCom('dados_invalidos'),
        );
        await expectLater(
          api.personalizarDiario('turma-1', AlteracoesDaCapa(frase: 'a' * 81)),
          erroCom('dados_invalidos'),
        );
        await api.personalizarDiario(
          'turma-1',
          AlteracoesDaCapa(titulo: '🍕' * 40, frase: '🍕' * 80),
        );
      },
    );
  });

  test(
    'o Diário traz as reações e o total de comentários de cada item',
    () async {
      final api = apiCom(
        encerradas: [encerrada('a2'), encerrada('a1')],
        reacoesPor: {
          'a1': [
            const Reacao(tipo: TipoDeReacao.risada, total: 3, minha: false),
          ],
        },
        comentariosPor: {
          'a1': [comentarioDeTeste(id: 'c1'), comentarioDeTeste(id: 'c2')],
        },
      );
      final pagina = await api.listarDiario('turma-1');

      expect(pagina.itens[0].atividade.id, 'a2');
      expect(pagina.itens[0].reacoes, isEmpty);
      expect(pagina.itens[0].totalDeComentarios, 0);
      expect(pagina.itens[1].reacoes.single.total, 3);
      expect(pagina.itens[1].totalDeComentarios, 2);
    },
  );
}
