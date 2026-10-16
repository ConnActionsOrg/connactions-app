import 'dart:convert';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'api_http_test.dart' show api, euJson, pessoaJson;

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response _erro(int status, String codigo, String mensagem) => _json({
  'erro': {'codigo': codigo, 'mensagem': mensagem},
}, status);

const _perfilJson = {
  ...pessoaJson,
  'bio': 'Trilha aos domingos',
  'contadores': {'turmas': 4, 'atividades': 23, 'conexoes': 18},
};

const _feitaJson = {
  'id': 'a1',
  'titulo': 'Piquenique no parque',
  'formato': 'grupo',
  'encerrada_em': '2026-10-15T22:10:05Z',
  'turma': {'nome': 'Turma do Domingo', 'emoji': '🌿'},
  'fotos': [
    {
      'foto_url': 'http://midia.local/midia/registros/a.jpg',
      'miniatura_url': 'http://midia.local/midia/registros/a.min.jpg',
      'legenda': 'Bolo de fubá',
    },
  ],
};

void main() {
  test('GET /conexoes lê as pessoas em itens, na ordem da API', () async {
    late http.Request visto;
    final pessoas = await api(
      MockClient((req) async {
        visto = req;
        return _json({
          'itens': [
            pessoaJson,
            {...pessoaJson, 'id': 'p2', 'handle': 'caio', 'nome': 'Caio Lima'},
          ],
        });
      }),
    ).listarConexoes();

    expect(visto.method, 'GET');
    expect(visto.url.path, '/v1/conexoes');
    expect(pessoas.map((p) => p.handle), ['bia', 'caio']);
  });

  test(
    'POST /conexoes manda o código; 201 é conexão nova e 200, a que já existia',
    () async {
      late http.Request visto;
      var status = 201;
      final cliente = api(
        MockClient((req) async {
          visto = req;
          return _json(pessoaJson, status);
        }),
      );

      final nova = await cliente.conectar('ABCD2345');
      expect(visto.method, 'POST');
      expect(visto.url.path, '/v1/conexoes');
      expect(jsonDecode(visto.body), {'codigo': 'ABCD2345'});
      expect(visto.headers['Content-Type'], contains('application/json'));
      expect(nova.pessoa.nome, 'Bia Souza');
      expect(nova.nova, isTrue);

      status = 200;
      final repetida = await cliente.conectar('ABCD2345');
      expect(repetida.pessoa.id, 'p1');
      expect(repetida.nova, isFalse);
    },
  );

  test('DELETE /conexoes/{id} aceita 204 sem corpo', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response('', 204);
      }),
    ).desconectar('p1');

    expect(visto.method, 'DELETE');
    expect(visto.url.path, '/v1/conexoes/p1');
  });

  test(
    'POST /eu/codigo-de-amigo vai sem corpo e lê o Eu com o código novo',
    () async {
      late http.Request visto;
      final eu = await api(
        MockClient((req) async {
          visto = req;
          return _json({...euJson, 'codigo_de_amigo': 'WXYZ6789'});
        }),
      ).regenerarCodigoDeAmigo();

      expect(visto.method, 'POST');
      expect(visto.url.path, '/v1/eu/codigo-de-amigo');
      expect(visto.body, isEmpty);
      expect(eu.codigoDeAmigo, 'WXYZ6789');
    },
  );

  test(
    'GET /usuarios/{id} lê a bio e os contadores; o de atividades pode vir nulo',
    () async {
      late http.Request visto;
      Map<String, Object?> corpo = _perfilJson;
      final cliente = api(
        MockClient((req) async {
          visto = req;
          return _json(corpo);
        }),
      );

      final perfil = await cliente.obterPerfil('p1');
      expect(visto.method, 'GET');
      expect(visto.url.path, '/v1/usuarios/p1');
      expect(perfil.nome, 'Bia Souza');
      expect(perfil.bio, 'Trilha aos domingos');
      expect([perfil.turmas, perfil.atividades, perfil.conexoes], [4, 23, 18]);

      corpo = {
        ..._perfilJson,
        'contadores': {'turmas': 4, 'atividades': null, 'conexoes': 18},
      };
      expect((await cliente.obterPerfil('p1')).atividades, isNull);
    },
  );

  test(
    'GET /usuarios/{id}/atividades manda o cursor e o limite e lê a página',
    () async {
      late http.Request visto;
      final pagina = await api(
        MockClient((req) async {
          visto = req;
          return _json({
            'itens': [_feitaJson],
            'proximo': 'c2',
          });
        }),
      ).listarAtividadesFeitas('p1', apos: 'c1', limite: 5);

      expect(visto.method, 'GET');
      expect(visto.url.path, '/v1/usuarios/p1/atividades');
      expect(visto.url.queryParameters, {'apos': 'c1', 'limite': '5'});
      final feita = pagina.itens.single;
      expect(feita.titulo, 'Piquenique no parque');
      expect(feita.formato, FormatoDeAtividade.grupo);
      expect(feita.encerradaEm, DateTime.utc(2026, 10, 15, 22, 10, 5));
      expect(feita.turmaEmoji, '🌿');
      expect(feita.fotos.single.legenda, 'Bolo de fubá');
      expect(pagina.proximo, 'c2');

      await api(
        MockClient((req) async {
          visto = req;
          return _json({'itens': <Object>[], 'proximo': null});
        }),
      ).listarAtividadesFeitas('p1');
      expect(visto.url.queryParameters, {'limite': '20'});
    },
  );

  test('o 422 e os 403 do contrato chegam com a mensagem pronta', () async {
    await expectLater(
      api(
        MockClient(
          (_) async => _erro(
            422,
            'codigo_invalido',
            'Não achei ninguém com esse código de amigo.',
          ),
        ),
      ).conectar('ABCD2345'),
      throwsA(
        isA<ErroDaApi>()
            .having((e) => e.codigoInvalido, 'codigoInvalido', isTrue)
            .having(
              (e) => e.mensagem,
              'mensagem',
              'Não achei ninguém com esse código de amigo.',
            ),
      ),
    );
    await expectLater(
      api(
        MockClient(
          (_) async => _erro(403, 'sem_acesso', 'Vocês não estão conectados.'),
        ),
      ).obterPerfil('p1'),
      throwsA(
        isA<ErroDaApi>()
            .having((e) => e.semAcesso, 'semAcesso', isTrue)
            .having(
              (e) => e.mensagem,
              'mensagem',
              'Vocês não estão conectados.',
            ),
      ),
    );
    await expectLater(
      api(
        MockClient(
          (_) async =>
              _erro(403, 'sem_acesso', 'Essas atividades não estão visíveis.'),
        ),
      ).listarAtividadesFeitas('p1'),
      throwsA(
        isA<ErroDaApi>().having(
          (e) => e.mensagem,
          'mensagem',
          'Essas atividades não estão visíveis.',
        ),
      ),
    );
  });
}
