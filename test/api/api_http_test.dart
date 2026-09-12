import 'dart:convert';

import 'package:connactions_app/api/api_http.dart';
import 'package:connactions_app/api/erro_da_api.dart';
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
    ).atualizarVisibilidade(visiveis: false);

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
}
