import 'dart:convert';
import 'dart:typed_data';

import 'package:connactions_app/api/api_http.dart';
import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/alteracoes_do_eu.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/api/modelos/proposta.dart';
import 'package:connactions_app/api/modelos/reacao.dart';
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

const pessoaJson = {
  'id': 'p1',
  'handle': 'bia',
  'nome': 'Bia Souza',
  'foto_url': null,
};

// Não pode se chamar turmaJson: o `const turmaJson` local de `main` (turma t1) o sombrearia.
const turmaDaAtividadeJson = {
  'id': 'turma-1',
  'nome': 'Turma',
  'emoji': '🌿',
  'codigo_convite': 'ABCD2345',
  'criador_id': 'a1',
  'vez_de': pessoaJson,
  'total_de_membros': 2,
  'criado_em': '2026-09-15T12:00:00Z',
};

const atividadeJson = {
  'id': 'ativ-1',
  'turma_id': 'turma-1',
  'numero': 1,
  'proponente': pessoaJson,
  'titulo': 'Piquenique',
  'descricao': '',
  'regras': <String>[],
  'formato': 'grupo',
  'publica': true,
  'prazo': null,
  'lancada_em': '2026-09-29T12:00:00Z',
  'encerrada_em': null,
  'registros': <Object>[],
};

const ideiaJson = {
  'id': 'i1',
  'titulo': 'Noite de pizza',
  'descricao': '',
  'regras': <String>[],
  'formato': null,
  'origem_atividade_id': null,
  'autor': pessoaJson,
  'criado_em': '2026-10-06T12:00:00Z',
};

const itemDaComunidadeJson = {
  'id': 'com-1',
  'titulo': 'Noite de jogos',
  'descricao': 'Cada um leva um jogo.',
  'regras': <String>['Um jogo por pessoa'],
  'formato': 'grupo',
  'encerrada_em': '2026-10-04T21:30:00Z',
  'turma': {'nome': 'Turma Prova', 'emoji': '🍕'},
  'fotos': [
    {
      'foto_url': 'http://midia.local/midia/registros/x.jpg',
      'miniatura_url': 'http://midia.local/midia/registros/x.min.jpg',
      'legenda': 'Vitória da Bia',
    },
  ],
  'inspiradas': 2,
};

const registroJson = {
  'id': 'reg-1',
  'autor': pessoaJson,
  'foto_url': 'http://midia.local/midia/registros/x.jpg',
  'miniatura_url': 'http://midia.local/midia/registros/x.min.jpg',
  'legenda': 'Bolo',
  'criado_em': '2026-09-29T13:00:00Z',
};

final fotoDeTeste = FotoParaEnviar(
  bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
  nome: 'foto.jpg',
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
    'criador_id': 'a9',
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

  test('GET atividade-aberta devolve null quando não há', () async {
    final api_ = api(
      MockClient(
        (_) async => http.Response(jsonEncode({'atividade': null}), 200),
      ),
    );
    expect(await api_.obterAtividadeAberta('turma-1'), isNull);
  });

  test('GET atividade-aberta devolve a atividade embutida', () async {
    late http.Request visto;
    final a = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(jsonEncode({'atividade': atividadeJson}), 200);
      }),
    ).obterAtividadeAberta('turma-1');
    expect(visto.url.path, '/v1/turmas/turma-1/atividade-aberta');
    expect(a?.id, 'ativ-1');
  });

  test('POST atividades manda a proposta', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response(jsonEncode(atividadeJson), 201);
      }),
    ).lancarAtividade(
      'turma-1',
      const Proposta(
        titulo: 'Piquenique',
        formato: FormatoDeAtividade.grupo,
        publica: true,
      ),
    );
    expect(visto.method, 'POST');
    expect(visto.url.path, '/v1/turmas/turma-1/atividades');
    expect(jsonDecode(visto.body), {
      'titulo': 'Piquenique',
      'descricao': '',
      'formato': 'grupo',
      'publica': true,
    });
  });

  test('POST encerrar devolve atividade e turma', () async {
    late http.Request visto;
    final e = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({
            'atividade': {
              ...atividadeJson,
              'encerrada_em': '2026-09-30T10:00:00Z',
            },
            'turma': turmaDaAtividadeJson,
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    ).encerrarAtividade('ativ-1');
    expect(visto.url.path, '/v1/atividades/ativ-1/encerrar');
    expect(e.atividade.aberta, isFalse);
    expect(e.turma.vezDe.id, 'p1');
  });

  test('registrar manda multipart com a foto e a legenda', () async {
    late http.Request visto;
    final r = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(jsonEncode(registroJson), 201);
      }),
    ).registrar('ativ-1', foto: fotoDeTeste, legenda: 'Bolo');
    expect(visto.method, 'POST');
    expect(visto.url.path, '/v1/atividades/ativ-1/registros');
    expect(visto.headers['Authorization'], 'Bearer tok');
    expect(visto.headers['content-type'], startsWith('multipart/form-data'));
    final corpo = String.fromCharCodes(visto.bodyBytes);
    expect(corpo, contains('name="foto"'));
    expect(corpo, contains('filename="foto.jpg"'));
    expect(corpo, contains('name="legenda"'));
    expect(corpo, contains('Bolo'));
    expect(r.legenda, 'Bolo');
  });

  test('DELETE registro aceita 204 sem corpo', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response('', 204);
      }),
    ).apagarRegistro('reg-1');
    expect(visto.method, 'DELETE');
    expect(visto.url.path, '/v1/registros/reg-1');
  });

  test('GET diario manda o cursor e o limite', () async {
    late http.Request visto;
    final p = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({
            'itens': [
              {
                ...atividadeJson,
                'reacoes': [
                  {'tipo': 'coracao', 'total': 2, 'minha': true},
                  {'tipo': 'unicornio', 'total': 9, 'minha': false},
                ],
                'total_de_comentarios': 3,
              },
            ],
            'proximo': 'c2',
            'capa': {
              'titulo': 'Noites de quinta',
              'frase': null,
              'paleta': 'salvia',
              'sticker': 'pizza',
              'atividades': 12,
              'fotos': 47,
            },
          }),
          200,
        );
      }),
    ).listarDiario('turma-1', apos: 'c1', limite: 5);
    expect(visto.url.path, '/v1/turmas/turma-1/diario');
    expect(visto.url.queryParameters, {'apos': 'c1', 'limite': '5'});
    expect(p.itens.single.atividade.id, 'ativ-1');
    // a reação de um tipo que o app não conhece não derruba a página
    expect(p.itens.single.reacoes, const [
      Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true),
    ]);
    expect(p.itens.single.totalDeComentarios, 3);
    expect(p.proximo, 'c2');
    expect(p.capa!.titulo, 'Noites de quinta');
    expect(p.capa!.paleta, PaletaDoDiario.salvia);
    expect(p.capa!.sticker, StickerDoDiario.pizza);
    expect(p.capa!.atividades, 12);

    await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({'itens': <Object>[], 'proximo': null, 'capa': null}),
          200,
        );
      }),
    ).listarDiario('turma-1');
    expect(visto.url.queryParameters, {'limite': '20'});
  });

  test('GET ideias devolve as livres da turma', () async {
    late http.Request visto;
    final lista = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({
            'itens': [ideiaJson],
          }),
          200,
        );
      }),
    ).listarIdeias('turma-1');
    expect(visto.method, 'GET');
    expect(visto.url.path, '/v1/turmas/turma-1/ideias');
    expect(lista.single.titulo, 'Noite de pizza');
    expect(lista.single.autor.handle, 'bia');
  });

  test('POST ideias manda título e descrição', () async {
    late http.Request visto;
    final ideia = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(jsonEncode(ideiaJson), 201);
      }),
    ).criarIdeia('turma-1', titulo: 'Noite de pizza', descricao: 'Com forno');
    expect(visto.method, 'POST');
    expect(visto.url.path, '/v1/turmas/turma-1/ideias');
    expect(jsonDecode(visto.body), {
      'titulo': 'Noite de pizza',
      'descricao': 'Com forno',
    });
    expect(ideia.id, 'i1');
  });

  test('DELETE ideias/{id} e o 409 de ideia indisponível', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response('', 204);
      }),
    ).apagarIdeia('i1');
    expect(visto.method, 'DELETE');
    expect(visto.url.path, '/v1/ideias/i1');

    await expectLater(
      api(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'erro': {
                'codigo': 'ideia_indisponivel',
                'mensagem': 'Essa ideia já foi usada ou apagada.',
              },
            }),
            409,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ).apagarIdeia('i1'),
      throwsA(
        isA<ErroDaApi>()
            .having((e) => e.ideiaIndisponivel, 'ideiaIndisponivel', isTrue)
            .having((e) => e.conflito, 'conflito', isTrue),
      ),
    );
  });

  test('POST comunidade/{id}/salvar manda a turma de destino', () async {
    late http.Request visto;
    final ideia = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({...ideiaJson, 'origem_atividade_id': 'com-1'}),
          201,
        );
      }),
    ).salvarDaComunidade('com-1', turmaId: 'turma-1');
    expect(visto.method, 'POST');
    expect(visto.url.path, '/v1/comunidade/com-1/salvar');
    expect(jsonDecode(visto.body), {'turma_id': 'turma-1'});
    expect(ideia.origemAtividadeId, 'com-1');
  });

  test('GET comunidade manda o cursor e o limite', () async {
    late http.Request visto;
    final p = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({
            'itens': [itemDaComunidadeJson],
            'proximo': 'c2',
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ).listarComunidade(apos: 'c1', limite: 5);
    expect(visto.method, 'GET');
    expect(visto.url.path, '/v1/comunidade');
    expect(visto.url.queryParameters, {'apos': 'c1', 'limite': '5'});
    expect(p.itens.single.turmaNome, 'Turma Prova');
    expect(p.itens.single.inspiradas, 2);
    expect(p.proximo, 'c2');

    await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({'itens': <Object>[], 'proximo': null}),
          200,
        );
      }),
    ).listarComunidade();
    expect(visto.url.queryParameters, {'limite': '20'});
  });

  test('POST atividades manda a origem escolhida no Propor', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response(jsonEncode(atividadeJson), 201);
      }),
    ).lancarAtividade(
      'turma-1',
      const Proposta(
        titulo: 'Pizza',
        formato: FormatoDeAtividade.grupo,
        publica: true,
        origemIdeiaId: 'i1',
      ),
    );
    final corpo = jsonDecode(visto.body) as Map<String, dynamic>;
    expect(corpo['origem_ideia_id'], 'i1');
    expect(corpo.containsKey('origem_atividade_id'), isFalse);
  });

  test('POST embaralhar devolve o detalhe', () async {
    late http.Request visto;
    final d = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({
            ...turmaDaAtividadeJson,
            'membros': [
              {...pessoaJson, 'ordem': 1, 'entrou_em': '2026-09-15T12:00:00Z'},
            ],
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    ).embaralharOrdem('turma-1');
    expect(visto.method, 'POST');
    expect(visto.url.path, '/v1/turmas/turma-1/embaralhar');
    expect(d.membros.single.ordem, 1);
  });

  test('PUT eu/foto manda multipart e devolve o Eu', () async {
    late http.Request visto;
    final eu = await api(
      MockClient((req) async {
        visto = req;
        return http.Response(
          jsonEncode({
            ...euJson,
            'foto_url': 'http://midia.local/midia/perfis/n.jpg',
          }),
          200,
        );
      }),
    ).trocarFoto(fotoDeTeste);
    expect(visto.method, 'PUT');
    expect(visto.url.path, '/v1/eu/foto');
    expect(visto.headers['content-type'], startsWith('multipart/form-data'));
    expect(eu.fotoUrl, endsWith('perfis/n.jpg'));
  });

  test('erro no multipart vira ErroDaApi como no JSON', () async {
    final futuro = api(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'erro': {'codigo': 'foto_invalida', 'mensagem': 'Envie uma foto.'},
          }),
          422,
        ),
      ),
    ).trocarFoto(fotoDeTeste);
    await expectLater(
      futuro,
      throwsA(
        isA<ErroDaApi>().having((e) => e.fotoInvalida, 'fotoInvalida', isTrue),
      ),
    );
  });

  test('PUT /dispositivos manda o token e a plataforma e aceita 204', () async {
    late http.Request visto;
    await api(
      MockClient((req) async {
        visto = req;
        return http.Response('', 204);
      }),
    ).registrarDispositivo(token: 'token-fcm-1', plataforma: 'android');

    expect(visto.method, 'PUT');
    expect(visto.url.toString(), 'http://api.local/v1/dispositivos');
    expect(visto.headers['Authorization'], 'Bearer tok');
    expect(visto.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(visto.body), {
      'token': 'token-fcm-1',
      'plataforma': 'android',
    });
  });

  test(
    'DELETE /dispositivos/{token} leva o token do FCM inteiro num segmento',
    () async {
      // o formato do FCM: id da instância, ':' e o resto, com '-' e '_' pelo meio
      const token =
          'fGx3Tq9ZRkqW1c2v-_Ab:APA91bHq7sL0v_mP3xK9dQ2rT5uY8wZ1aB4cD7eF0gH3iJ6kL9mN2oP5qR8sT1uV4wX7yZ0aB3cD6eF9gH2iJ5kL8mN1oP4qR7sT0uV3wX6yZ9-_aB2cD5eF8gH1iJ4kL7mN0oP3qR6';
      late http.Request visto;
      await api(
        MockClient((req) async {
          visto = req;
          return http.Response('', 204);
        }),
      ).removerDispositivo(token);

      expect(token.length, 160);
      expect(visto.method, 'DELETE');
      // ':' vale num segmento de caminho: vai literal, e a rota do chi entrega o token sem decodificar
      expect(visto.url.toString(), 'http://api.local/v1/dispositivos/$token');
      expect(visto.url.pathSegments, ['v1', 'dispositivos', token]);
      expect(visto.body, isEmpty);
    },
  );

  test(
    'DELETE /dispositivos/{token}: um "/" no token não parte a rota',
    () async {
      late http.Request visto;
      await api(
        MockClient((req) async {
          visto = req;
          return http.Response('', 204);
        }),
      ).removerDispositivo('a/b');

      expect(visto.url.path, '/v1/dispositivos/a%2Fb');
      expect(visto.url.pathSegments, ['v1', 'dispositivos', 'a/b']);
    },
  );
}
