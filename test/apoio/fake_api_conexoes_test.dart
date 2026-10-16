import 'package:connactions_app/api/erro_da_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';

// O FakeApi tem de seguir as regras da API: se ele divergir, os testes de tela passam por um contrato
// que não existe. Aqui cada regra das conexões e do perfil aparece uma vez, contra o dublê.

final eu = pessoaDoEu(euDeTeste());

/// Eu na Turma do Domingo (turma-1); a Bia e o Caio são contas da API, e só o que o teste pedir os
/// conecta a mim. Contas novas a cada teste: o teste que desliga a visibilidade da Bia não vaza.
FakeApi apiCom({
  List<(String, String)> conexoes = const [],
  Map<String, List<Feita>> feitasPor = const {},
  bool biaVisivel = true,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  usuarios: [
    usuarioDeTeste(atividadesVisiveis: biaVisivel, turmas: 3),
    usuarioDeTeste(
      id: 'pessoa-caio',
      handle: 'caio',
      nome: 'Caio Lima',
      codigoDeAmigo: 'CKXZ2345',
    ),
  ],
  conexoes: conexoes,
  feitasPor: feitasPor,
);

Matcher erroCom(int status, String codigo, [String? mensagem]) => throwsA(
  isA<ErroDaApi>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.codigo, 'codigo', codigo)
      .having((e) => e.mensagem, 'mensagem', mensagem ?? isNotEmpty),
);

void main() {
  group('conectar', () {
    test(
      'o código de ninguém e o convite de uma turma são 422 com a mensagem do contrato',
      () async {
        final api = apiCom();
        for (final codigo in ['ZZZZ9999', turmaDeTeste().codigoConvite]) {
          await expectLater(
            api.conectar(codigo),
            erroCom(
              422,
              'codigo_invalido',
              'Não achei ninguém com esse código de amigo.',
            ),
          );
        }
        expect(await api.listarConexoes(), isEmpty);
      },
    );

    test('o meu próprio código é 422 com a mensagem própria', () async {
      await expectLater(
        apiCom().conectar(euDeTeste().codigoDeAmigo),
        erroCom(
          422,
          'codigo_invalido',
          'Esse é o seu código. Peça o do seu amigo.',
        ),
      );
    });

    test(
      'a nova devolve a pessoa e nova; a repetida, nova falso e sem duplicar',
      () async {
        final api = apiCom();
        // minúsculas e espaços, como chegam de quem digita: a API normaliza
        final nova = await api.conectar(' beaz 2345 ');
        expect(nova.pessoa.id, 'pessoa-bia');
        expect(nova.nova, isTrue);

        final repetida = await api.conectar('BEAZ2345');
        expect(repetida.pessoa.id, 'pessoa-bia');
        expect(repetida.nova, isFalse);
        expect((await api.listarConexoes()).map((p) => p.id), ['pessoa-bia']);
      },
    );

    test('a conexão vale para os dois lados', () async {
      final api = apiCom();
      await api.conectar('BEAZ2345');

      api.entrarComo('pessoa-bia');

      expect((await api.listarConexoes()).map((p) => p.id), [eu.id]);
      // e o perfil de quem era eu se abre do lado de lá
      expect((await api.obterPerfil(eu.id)).nome, 'Marina Duarte');
    });
  });

  group('lista e desconectar', () {
    test('a lista vem da conexão mais recente para a mais antiga', () async {
      final api = apiCom();
      await api.conectar('CKXZ2345');
      await api.conectar('BEAZ2345');

      expect((await api.listarConexoes()).map((p) => p.id), [
        'pessoa-bia',
        'pessoa-caio',
      ]);
    });

    test('desconectar some dos dois lados, e repetir não é erro', () async {
      // o par nasceu do lado da Bia (ela usou o meu código), e quem desconecta sou eu
      final api = apiCom(
        conexoes: [('pessoa-bia', eu.id), ('pessoa-caio', eu.id)],
      );

      await api.desconectar('pessoa-bia');
      await api.desconectar('pessoa-bia');

      expect((await api.listarConexoes()).map((p) => p.id), ['pessoa-caio']);
      api.entrarComo('pessoa-bia');
      expect(await api.listarConexoes(), isEmpty);
    });
  });

  test(
    'o código novo troca o meu, o antigo deixa de valer e as conexões ficam',
    () async {
      final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')]);
      final antigo = euDeTeste().codigoDeAmigo;

      final novo = (await api.regenerarCodigoDeAmigo()).codigoDeAmigo;
      expect(novo, isNot(antigo));
      expect((await api.obterEu()).codigoDeAmigo, novo);

      api.entrarComo('pessoa-bia');
      await expectLater(
        api.conectar(antigo),
        erroCom(
          422,
          'codigo_invalido',
          'Não achei ninguém com esse código de amigo.',
        ),
      );
      // o código novo é de quem já era conexão: vale, e não duplica
      expect((await api.conectar(novo)).nova, isFalse);
      expect((await api.listarConexoes()).map((p) => p.id), [eu.id]);
    },
  );

  group('perfil', () {
    test(
      'o meu traz os três contadores, e o de atividades mesmo só para mim',
      () async {
        final api = FakeApi(
          eu: euDeTeste(atividadesVisiveis: false),
          turmas: [
            turmaDeTeste(),
            turmaDeTeste(id: 'turma-2'),
          ],
          usuarios: [usuarioDeTeste()],
          conexoes: [(eu.id, 'pessoa-bia')],
          feitasPor: {
            eu.id: [
              feitaDeTeste(id: 'f1'),
              feitaDeTeste(id: 'f2'),
              feitaDeTeste(id: 'f3', publica: false),
            ],
          },
        );

        final perfil = await api.obterPerfil(eu.id);

        expect(perfil.nome, 'Marina Duarte');
        expect([perfil.turmas, perfil.atividades, perfil.conexoes], [2, 3, 1]);
      },
    );

    test(
      'o de uma conexão traz os dela; com a visibilidade desligada, sem o de atividades',
      () async {
        final api = apiCom(
          conexoes: [(eu.id, 'pessoa-bia'), ('pessoa-caio', 'pessoa-bia')],
          feitasPor: {
            'pessoa-bia': [feitaDeTeste(id: 'f1')],
          },
        );

        final perfil = await api.obterPerfil('pessoa-bia');
        expect(perfil.handle, 'bia');
        expect([perfil.turmas, perfil.atividades, perfil.conexoes], [3, 1, 2]);

        api.usuarios['pessoa-bia']!.atividadesVisiveis = false;
        final escondido = await api.obterPerfil('pessoa-bia');
        expect(escondido.atividades, isNull);
        expect([escondido.turmas, escondido.conexoes], [3, 2]);
      },
    );

    test('quem não é conexão é 403 e quem não existe, 404', () async {
      final api = apiCom();
      await expectLater(
        api.obterPerfil('pessoa-bia'),
        erroCom(403, 'sem_acesso', 'Vocês não estão conectados.'),
      );
      await expectLater(
        api.obterPerfil('ninguem'),
        erroCom(404, 'nao_encontrado'),
      );
    });
  });

  group('atividades feitas', () {
    Map<String, List<Feita>> feitasDaBia() => {
      'pessoa-bia': [
        feitaDeTeste(id: 'publica-de-fora', turmaId: 'turma-9'),
        feitaDeTeste(id: 'privada-da-minha', publica: false),
        feitaDeTeste(id: 'privada-de-fora', turmaId: 'turma-9', publica: false),
      ],
    };

    test(
      'no perfil de outra pessoa, só as públicas e as das minhas turmas; no meu, todas',
      () async {
        final api = apiCom(
          conexoes: [(eu.id, 'pessoa-bia')],
          feitasPor: {
            ...feitasDaBia(),
            eu.id: [
              feitaDeTeste(
                id: 'minha-privada',
                turmaId: 'turma-9',
                publica: false,
              ),
            ],
          },
        );

        final daBia = await api.listarAtividadesFeitas('pessoa-bia');
        expect(daBia.itens.map((a) => a.id), [
          'publica-de-fora',
          'privada-da-minha',
        ]);
        final minhas = await api.listarAtividadesFeitas(eu.id);
        expect(minhas.itens.map((a) => a.id), ['minha-privada']);
      },
    );

    test(
      'com a visibilidade dela desligada, a lista é 403 com a mensagem própria',
      () async {
        final api = apiCom(
          conexoes: [(eu.id, 'pessoa-bia')],
          feitasPor: feitasDaBia(),
          biaVisivel: false,
        );
        await expectLater(
          api.listarAtividadesFeitas('pessoa-bia'),
          erroCom(403, 'sem_acesso', 'Essas atividades não estão visíveis.'),
        );
      },
    );

    test('de quem não é conexão é 403 e de quem não existe, 404', () async {
      final api = apiCom(feitasPor: feitasDaBia());
      await expectLater(
        api.listarAtividadesFeitas('pessoa-bia'),
        erroCom(403, 'sem_acesso', 'Vocês não estão conectados.'),
      );
      await expectLater(
        api.listarAtividadesFeitas('ninguem'),
        erroCom(404, 'nao_encontrado'),
      );
    });

    test(
      'pagina pelo cursor; o cursor ruim é 422 e o limite tem teto de 50',
      () async {
        final api = apiCom(
          conexoes: [(eu.id, 'pessoa-bia')],
          feitasPor: {
            'pessoa-bia': [
              for (var i = 1; i <= 55; i++) feitaDeTeste(id: 'f$i'),
            ],
          },
        );

        final primeira = await api.listarAtividadesFeitas('pessoa-bia');
        expect(primeira.itens, hasLength(20));
        expect(primeira.proximo, '20');
        final fim = await api.listarAtividadesFeitas('pessoa-bia', apos: '50');
        expect(fim.itens.map((a) => a.id), ['f51', 'f52', 'f53', 'f54', 'f55']);
        expect(fim.proximo, isNull);
        expect(
          (await api.listarAtividadesFeitas('pessoa-bia', limite: 100)).itens,
          hasLength(50),
        );

        await expectLater(
          api.listarAtividadesFeitas('pessoa-bia', apos: 'lixo'),
          erroCom(422, 'dados_invalidos', 'Cursor inválido.'),
        );
        await expectLater(
          api.listarAtividadesFeitas('pessoa-bia', limite: 0),
          erroCom(
            422,
            'dados_invalidos',
            'O limite precisa ser um número a partir de 1.',
          ),
        );
      },
    );
  });
}
