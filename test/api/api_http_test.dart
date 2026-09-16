import 'dart:convert';

import 'package:connactions_app/api/api_http.dart';
import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/alteracoes_do_eu.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const euJson = {
  'id': 'a1',
  'handle': 'marina.duarte',
  'nome': 'Marina Duarte',
  'foto_url': 'https://exemplo.com/marina.jpg',
  'bio': '',
  'codigo_de_amigo': 'ABCDEFGH',
  'atividades_visiveis': true,
  'criado_em': '2026-09-11T12:00:00Z',
};

ApiHttp api(MockClient cliente, {String? token = 'tok'}) => ApiHttp(
  base: Uri.parse('http://api.local/v1'),
  obterToken: () async => token,
  cliente: cliente,
);

void main() {
  test('POST /eu manda o bearer, no caminho certo, e devolve o Eu', () async {
    late http.Request visto;
    final eu = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(jsonEncode(euJson), 201);
      }),
    ).criarEu();

    expect(visto.method, 'POST');
    expect(visto.url.toString(), 'http://api.local/v1/eu');
    expect(visto.headers['Authorization'], 'Bearer tok');
    expect(eu.handle, 'marina.duarte');
  });

  test('PATCH /eu manda o corpo JSON', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({...euJson, 'atividades_visiveis': false}),
          200,
        );
      }),
    ).atualizarEu(const AlteracoesDoEu(atividadesVisiveis: false));

    expect(visto.method, 'PATCH');
    expect(jsonDecode(visto.body), {'atividades_visiveis': false});
    expect(visto.headers['Content-Type'], startsWith('application/json'));
  });

  test('erro da API vira ErroDaApi com o código do envelope', () async {
    final futuro = api(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'erro': {
              'codigo': 'perfil_nao_criado',
              'mensagem': 'Crie seu perfil.',
            },
          }),
          403,
        ),
      ),
    ).obterEu();

    await expectLater(
      futuro,
      throwsA(
        isA<ErroDaApi>()
            .having((e) => e.status, 'status', 403)
            .having((e) => e.codigo, 'codigo', 'perfil_nao_criado')
            .having((e) => e.perfilNaoCriado, 'perfilNaoCriado', isTrue)
            .having((e) => e.mensagem, 'mensagem', 'Crie seu perfil.'),
      ),
    );
  });

  test('sem token não chama a rede e falha como não autenticado', () async {
    var chamouRede = false;
    final futuro = api(
      MockClient((_) async {
        chamouRede = true;
        return http.Response('{}', 200);
      }),
      token: null,
    ).obterEu();

    await expectLater(
      futuro,
      throwsA(
        isA<ErroDaApi>().having(
          (e) => e.naoAutenticado,
          'naoAutenticado',
          isTrue,
        ),
      ),
    );
    expect(chamouRede, isFalse);
  });

  test('obterToken que lança vira ErroDeRede', () async {
    var chamouRede = false;
    final futuro = ApiHttp(
      base: Uri.parse('http://api.local/v1'),
      obterToken: () async => throw Exception('sem rede'),
      cliente: MockClient((_) async {
        chamouRede = true;
        return http.Response('{}', 200);
      }),
    ).obterEu();

    await expectLater(futuro, throwsA(isA<ErroDeRede>()));
    expect(chamouRede, isFalse);
  });

  test('falha de conexão vira ErroDeRede', () async {
    final futuro = api(
      MockClient((_) async => throw http.ClientException('caiu')),
    ).obterEu();
    await expectLater(futuro, throwsA(isA<ErroDeRede>()));
  });

  test('502 com HTML do proxy vira ErroDaApi erro_desconhecido', () async {
    final futuro = api(
      MockClient((_) async => http.Response('<html>Bad Gateway</html>', 502)),
    ).obterEu();

    await expectLater(
      futuro,
      throwsA(
        isA<ErroDaApi>()
            .having((e) => e.status, 'status', 502)
            .having((e) => e.codigo, 'codigo', 'erro_desconhecido'),
      ),
    );
  });

  test(
    '200 com corpo que não é JSON vira ErroDaApi resposta_invalida',
    () async {
      final futuro = api(
        MockClient((_) async => http.Response('nao e json', 200)),
      ).obterEu();

      await expectLater(
        futuro,
        throwsA(
          isA<ErroDaApi>().having(
            (e) => e.codigo,
            'codigo',
            'resposta_invalida',
          ),
        ),
      );
    },
  );

  const turmaJson = {
    'id': 't1',
    'nome': 'Turma do Domingo',
    'emoji': '🌿',
    'codigo_convite': 'ABCD2345',
    'criador_id': 'a1',
    'vez_de': {
      'id': 'a1',
      'handle': 'marina.duarte',
      'nome': 'Marina Duarte',
      'foto_url': null,
    },
    'total_de_membros': 1,
    'criado_em': '2026-09-15T12:00:00Z',
  };

  test('GET /turmas lê a lista em itens', () async {
    late http.Request visto;
    final turmas = await api(
      MockClient((req) async {
        visto = req;
        // content-type explícito: sem ele o http.Response assume Latin-1 (RFC 2616) e o emoji
        // do fixture não cabe nem no encode — o cliente sempre lê a resposta como UTF-8.
        return http.Response(
          jsonEncode({
            'itens': [turmaJson],
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    ).listarTurmas();

    expect(visto.method, 'GET');
    expect(visto.url.toString(), 'http://api.local/v1/turmas');
    expect(turmas.single.nome, 'Turma do Domingo');
  });

  test('GET /turmas com itens vazio devolve lista vazia', () async {
    final turmas = await api(
      MockClient((_) async => http.Response(jsonEncode({'itens': []}), 200)),
    ).listarTurmas();
    expect(turmas, isEmpty);
  });

  test('POST /turmas manda nome e emoji', () async {
    late http.Request visto;
    final turma = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode(turmaJson),
          201,
          headers: const {'content-type': 'application/json'},
        );
      }),
    ).criarTurma(nome: 'Turma do Domingo', emoji: '🌿');

    expect(visto.method, 'POST');
    expect(visto.url.toString(), 'http://api.local/v1/turmas');
    expect(jsonDecode(visto.body), {'nome': 'Turma do Domingo', 'emoji': '🌿'});
    expect(turma.id, 't1');
  });

  test('POST /turmas/entrar manda o código', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode(turmaJson),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    ).entrarNaTurma(codigo: 'ABCD2345');

    expect(visto.url.toString(), 'http://api.local/v1/turmas/entrar');
    expect(jsonDecode(visto.body), {'codigo': 'ABCD2345'});
  });

  test('GET /turmas/{id} lê o detalhe com membros', () async {
    late http.Request visto;
    final detalhe = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({
            ...turmaJson,
            'membros': [
              {
                ...(turmaJson['vez_de'] as Map),
                'ordem': 1,
                'entrou_em': '2026-09-15T12:00:00Z',
              },
            ],
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    ).obterTurma('t1');

    expect(visto.method, 'GET');
    expect(visto.url.toString(), 'http://api.local/v1/turmas/t1');
    expect(detalhe.turma.id, 't1');
    expect(detalhe.membros.single.pessoa.handle, 'marina.duarte');
  });

  test('POST /turmas/{id}/convite não manda corpo e lê a turma', () async {
    late http.Request visto;
    final turma = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({...turmaJson, 'codigo_convite': 'WXYZ6789'}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    ).regenerarConvite('t1');

    expect(visto.method, 'POST');
    expect(visto.url.toString(), 'http://api.local/v1/turmas/t1/convite');
    expect(visto.body, isEmpty);
    expect(turma.codigoConvite, 'WXYZ6789');
  });

  test('DELETE /turmas/{id}/membros/eu aceita 204 sem corpo', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response('', 204);
      }),
    ).sairDaTurma('t1');

    expect(visto.method, 'DELETE');
    expect(visto.url.toString(), 'http://api.local/v1/turmas/t1/membros/eu');
  });

  test('422 codigo_invalido vira ErroDaApi.codigoInvalido', () async {
    final futuro = api(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'erro': {
              'codigo': 'codigo_invalido',
              'mensagem': 'Código inválido. Confira com quem te convidou.',
            },
          }),
          422,
          headers: const {'content-type': 'application/json'},
        ),
      ),
    ).entrarNaTurma(codigo: 'ABCD2345');

    await expectLater(
      futuro,
      throwsA(
        isA<ErroDaApi>()
            .having((e) => e.codigoInvalido, 'codigoInvalido', isTrue)
            .having((e) => e.handleEmUso, 'handleEmUso', isFalse),
      ),
    );
  });
}
