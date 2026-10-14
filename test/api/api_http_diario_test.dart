import 'dart:convert';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/api/modelos/reacao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'api_http_test.dart' show api, pessoaJson;

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _comentarioJson = {
  'id': 'com-1',
  'autor': pessoaJson,
  'texto': 'Foi demais!',
  'criado_em': '2026-10-14T15:01:51Z',
  'meu': true,
};

void main() {
  test('PUT reação manda o slug no caminho e lê o resumo devolvido', () async {
    late http.Request visto;
    final resumo = await api(
      MockClient((req) async {
        visto = req;
        return _json({
          'reacoes': [
            {'tipo': 'coracao', 'total': 2, 'minha': true},
            {'tipo': 'unicornio', 'total': 1, 'minha': false},
          ],
        });
      }),
    ).reagir('ativ-1', TipoDeReacao.coracao);

    expect(visto.method, 'PUT');
    expect(visto.url.path, '/v1/atividades/ativ-1/reacoes/coracao');
    expect(visto.body, isEmpty);
    // o tipo que o app não conhece fica de fora, e o resto da resposta vale
    expect(resumo, const [
      Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true),
    ]);
  });

  test('DELETE reação usa o mesmo caminho e aceita a lista vazia', () async {
    late http.Request visto;
    final resumo = await api(
      MockClient((req) async {
        visto = req;
        return _json({'reacoes': <Object>[]});
      }),
    ).desreagir('ativ-1', TipoDeReacao.festa);

    expect(visto.method, 'DELETE');
    expect(visto.url.path, '/v1/atividades/ativ-1/reacoes/festa');
    expect(resumo, isEmpty);
  });

  test('o glifo nunca vai para a URL: só o slug em ASCII', () async {
    final caminhos = <String>[];
    final cliente = api(
      MockClient((req) async {
        caminhos.add(req.url.path);
        return _json({'reacoes': <Object>[]});
      }),
    );
    for (final tipo in TipoDeReacao.values) {
      await cliente.reagir('ativ-1', tipo);
    }
    expect(caminhos, hasLength(TipoDeReacao.values.length));
    for (final caminho in caminhos) {
      expect(
        caminho,
        matches(RegExp(r'^/v1/atividades/ativ-1/reacoes/[a-z]+$')),
      );
    }
  });

  test(
    'GET comentários manda o cursor e o limite e lê autor e "meu"',
    () async {
      late http.Request visto;
      final p = await api(
        MockClient((req) async {
          visto = req;
          return _json({
            'itens': [_comentarioJson],
            'proximo': 'c2',
          });
        }),
      ).listarComentarios('ativ-1', apos: 'c1', limite: 10);

      expect(visto.method, 'GET');
      expect(visto.url.path, '/v1/atividades/ativ-1/comentarios');
      expect(visto.url.queryParameters, {'apos': 'c1', 'limite': '10'});
      expect(p.itens.single.texto, 'Foi demais!');
      expect(p.itens.single.meu, isTrue);
      expect(p.itens.single.autor.nome, 'Bia Souza');
      expect(p.proximo, 'c2');

      await api(
        MockClient((req) async {
          visto = req;
          return _json({'itens': <Object>[], 'proximo': null});
        }),
      ).listarComentarios('ativ-1');
      expect(visto.url.queryParameters, {'limite': '50'});
    },
  );

  test(
    'POST comentário manda o texto em JSON e lê o comentário criado',
    () async {
      late http.Request visto;
      final c = await api(
        MockClient((req) async {
          visto = req;
          return _json(_comentarioJson, 201);
        }),
      ).comentar('ativ-1', 'Foi demais!');

      expect(visto.method, 'POST');
      expect(visto.url.path, '/v1/atividades/ativ-1/comentarios');
      expect(jsonDecode(visto.body), {'texto': 'Foi demais!'});
      expect(visto.headers['Content-Type'], contains('application/json'));
      expect(c.id, 'com-1');
      expect(c.meu, isTrue);
    },
  );

  test('DELETE comentário aceita 204 sem corpo', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response('', 204);
      }),
    ).apagarComentario('com-1');

    expect(visto.method, 'DELETE');
    expect(visto.url.path, '/v1/comentarios/com-1');
  });

  test('PATCH diário manda só o que mudou, pelo slug, e lê a capa', () async {
    late http.Request visto;
    final capa =
        await api(
          MockClient((req) async {
            visto = req;
            return _json({
              'titulo': 'Noites de quinta',
              'frase': null,
              'paleta': 'terracota',
              'sticker': 'pizza',
              'atividades': 3,
              'fotos': 9,
            });
          }),
        ).personalizarDiario(
          'turma-1',
          const AlteracoesDaCapa(
            titulo: 'Noites de quinta',
            paleta: PaletaDoDiario.terracota,
            sticker: StickerDoDiario.pizza,
          ),
        );

    expect(visto.method, 'PATCH');
    expect(visto.url.path, '/v1/turmas/turma-1/diario');
    expect(jsonDecode(visto.body), {
      'titulo': 'Noites de quinta',
      'paleta': 'terracota',
      'sticker': 'pizza',
    });
    expect(capa.titulo, 'Noites de quinta');
    expect(capa.frase, isNull);
    expect(capa.atividades, 3);
    expect(capa.fotos, 9);
  });

  test(
    '409 atividade_aberta vira ErroDaApi.atividadeAberta (e conflito)',
    () async {
      await expectLater(
        api(
          MockClient(
            (req) async => _json({
              'erro': {
                'codigo': 'atividade_aberta',
                'mensagem':
                    'Reações e comentários começam quando a atividade é encerrada.',
              },
            }, 409),
          ),
        ).reagir('ativ-1', TipoDeReacao.coracao),
        throwsA(
          isA<ErroDaApi>()
              .having((e) => e.atividadeAberta, 'atividadeAberta', isTrue)
              .having((e) => e.conflito, 'conflito', isTrue),
        ),
      );
    },
  );
}
