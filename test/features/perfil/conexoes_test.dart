import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/app/sessao.dart';
import 'package:connactions_app/features/perfil/conexoes.dart';
import 'package:connactions_app/features/perfil/perfil_da_pessoa.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/autenticador_falso.dart';
import '../../apoio/container_de_teste.dart';
import '../../apoio/erros_sem_dono.dart';
import '../../apoio/fake_api.dart';

final eu = pessoaDoEu(euDeTeste());

/// Eu conectado a quem o teste disser; a Bia, o Caio e a Dani são contas da API.
FakeApi apiCom({List<(String, String)> conexoes = const []}) => FakeApi(
  eu: euDeTeste(),
  usuarios: [
    usuarioDeTeste(),
    usuarioDeTeste(
      id: 'pessoa-caio',
      handle: 'caio',
      nome: 'Caio Lima',
      codigoDeAmigo: 'CKXZ2345',
    ),
    usuarioDeTeste(
      id: 'pessoa-dani',
      handle: 'dani',
      nome: 'Dani Rocha',
      codigoDeAmigo: 'DNRX2345',
    ),
  ],
  conexoes: conexoes,
);

ProviderContainer montar(FakeApi api, {AutenticadorFalso? autenticador}) {
  final c = containerDeTeste(api, autenticador: autenticador);
  // sem ouvinte o Riverpod pausa a cadeia conta → perfil → conexões e o .future nunca resolve
  c.listen(perfilAtualProvider, (_, _) {});
  c.listen(conexoesProvider, (_, _) {});
  return c;
}

List<String> idsDe(ProviderContainer c) => [
  for (final p in c.read(conexoesProvider).value ?? const <Pessoa>[]) p.id,
];

int leituras(FakeApi api, String chamada) =>
    api.chamadas.where((c) => c == chamada).length;

Future<void> ticks() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('lista as conexões depois de garantir o perfil', () async {
    final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')]);
    final c = montar(api);

    final amigos = await c.read(conexoesProvider.future);

    expect(amigos.map((p) => p.nome), ['Bia Souza']);
    expect(api.chamadas, ['obterEu', 'listarConexoes']);
  });

  test('a lista carrega sem outra tela ouvindo o perfil', () async {
    final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')]);
    final c = containerDeTeste(api);
    c.listen(conexoesProvider, (_, _) {});

    final amigos = await c
        .read(conexoesProvider.future)
        .timeout(const Duration(seconds: 2));

    expect(amigos.map((p) => p.nome), ['Bia Souza']);
  });

  test('sem conta, vazia e sem chamar a API', () async {
    final api = apiCom();
    final c = montar(api, autenticador: AutenticadorFalso());

    expect(await c.read(conexoesProvider.future), isEmpty);
    expect(api.chamadas, isEmpty);
  });

  test('a falha ao listar vira erro e não é repetida sozinha', () async {
    final api = apiCom()..falhaAoListarConexoes = const ErroDeRede('caiu');
    final c = montar(api);

    // o retry padrão do Riverpod 3 tentaria de novo em 200 ms
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(leituras(api, 'listarConexoes'), 1);
    expect(c.read(conexoesProvider).error, isA<ErroDeRede>());
  });

  test('a lista volta sozinha quando o perfil que falhou volta', () async {
    final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')])
      ..falhaAoObter = const ErroDeRede('caiu');
    final c = montar(api);
    await expectLater(
      c.read(conexoesProvider.future),
      throwsA(isA<ErroDeRede>()),
    );

    // o "Tentar de novo" do Perfil só relê o perfil
    api.falhaAoObter = null;
    c.invalidate(perfilAtualProvider);
    await c.read(perfilAtualProvider.future);
    await ticks();

    final depois = c.read(conexoesProvider.future);
    expect(await erroDe(depois), isNull);
    expect((await depois).map((p) => p.id), ['pessoa-bia']);
  });

  test(
    'mudar a visibilidade ou gerar um código novo não relê a lista',
    () async {
      final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')]);
      final c = montar(api);
      await c.read(conexoesProvider.future);

      await c.read(perfilAtualProvider.notifier).definirVisibilidade(false);
      await c.read(perfilAtualProvider.notifier).regenerarCodigo();
      await ticks();

      expect(leituras(api, 'listarConexoes'), 1);
      expect(idsDe(c), ['pessoa-bia']);
    },
  );

  group('conectar', () {
    test('a pessoa nova entra na ponta e o record volta para a tela', () async {
      final c = montar(apiCom(conexoes: [(eu.id, 'pessoa-caio')]));
      await c.read(conexoesProvider.future);

      final r = await c.read(conexoesProvider.notifier).conectar('BEAZ2345');

      expect(r.nova, isTrue);
      expect(r.pessoa.primeiroNome, 'Bia');
      expect(idsDe(c), ['pessoa-bia', 'pessoa-caio']);
    });

    test('a repetida não duplica nem muda de lugar', () async {
      final c = montar(
        apiCom(conexoes: [(eu.id, 'pessoa-bia'), (eu.id, 'pessoa-caio')]),
      );
      await c.read(conexoesProvider.future);

      final r = await c.read(conexoesProvider.notifier).conectar('CKXZ2345');

      expect(r.nova, isFalse);
      expect(idsDe(c), ['pessoa-bia', 'pessoa-caio']);
    });

    test(
      'a que a lista não sabia (a pessoa conectou do aparelho dela) entra na ponta',
      () async {
        final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')]);
        final c = montar(api);
        await c.read(conexoesProvider.future);
        api.conexoes.insert(0, ('pessoa-caio', eu.id));

        final r = await c.read(conexoesProvider.notifier).conectar('CKXZ2345');

        expect(r.nova, isFalse);
        expect(idsDe(c), ['pessoa-caio', 'pessoa-bia']);
      },
    );

    test('os meus contadores são relidos', () async {
      final api = apiCom();
      final c = montar(api);
      c.listen(perfilDaPessoaProvider(eu.id), (_, _) {});
      await c.read(conexoesProvider.future);
      expect((await c.read(perfilDaPessoaProvider(eu.id).future)).conexoes, 0);

      await c.read(conexoesProvider.notifier).conectar('BEAZ2345');

      expect((await c.read(perfilDaPessoaProvider(eu.id).future)).conexoes, 1);
      expect(leituras(api, 'obterPerfil:${eu.id}'), 2);
    });

    test('o erro sobe e a lista fica como estava', () async {
      final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')]);
      final c = montar(api);
      await c.read(conexoesProvider.future);

      await expectLater(
        c.read(conexoesProvider.notifier).conectar('ZZZZ9999'),
        throwsA(
          isA<ErroDaApi>().having(
            (e) => e.codigoInvalido,
            'codigoInvalido',
            isTrue,
          ),
        ),
      );
      expect(idsDe(c), ['pessoa-bia']);
      expect(leituras(api, 'listarConexoes'), 1);
    });

    test(
      'espera a lista em voo, e o build que chega não apaga a pessoa nova',
      () async {
        final api = apiCom(conexoes: [(eu.id, 'pessoa-caio')])
          ..segurarListarConexoes = Completer<void>();
        final c = montar(api);

        final futuro = c.read(conexoesProvider.notifier).conectar('BEAZ2345');
        await ticks();
        expect(api.chamadas, isNot(contains('conectar:BEAZ2345')));

        api.segurarListarConexoes!.complete();
        await futuro;

        expect(
          api.chamadas.indexOf('listarConexoes'),
          lessThan(api.chamadas.indexOf('conectar:BEAZ2345')),
        );
        expect(idsDe(c), ['pessoa-bia', 'pessoa-caio']);
      },
    );

    test(
      'a lista que falhou ao carregar não prende o conectar, e é relida',
      () async {
        final api = apiCom()..falhaAoListarConexoes = const ErroDeRede('caiu');
        final c = montar(api);
        await expectLater(
          c.read(conexoesProvider.future),
          throwsA(isA<ErroDeRede>()),
        );
        api.falhaAoListarConexoes = null;

        final conectar = c.read(conexoesProvider.notifier).conectar('BEAZ2345');

        expect(await erroDe(conectar), isNull);
        expect((await conectar).nova, isTrue);
        expect((await c.read(conexoesProvider.future)).map((p) => p.id), [
          'pessoa-bia',
        ]);
      },
    );
  });

  test(
    'desconectar tira a pessoa e relê o perfil e as atividades dela e os meus contadores',
    () async {
      final api = apiCom(
        conexoes: [(eu.id, 'pessoa-bia'), (eu.id, 'pessoa-caio')],
      );
      final c = montar(api);
      for (final p in [
        perfilDaPessoaProvider('pessoa-bia'),
        perfilDaPessoaProvider(eu.id),
      ]) {
        c.listen(p, (_, _) {});
        await c.read(p.future);
      }
      c.listen(atividadesFeitasProvider('pessoa-bia'), (_, _) {});
      await c.read(atividadesFeitasProvider('pessoa-bia').future);
      await c.read(conexoesProvider.future);

      await c.read(conexoesProvider.notifier).desconectar('pessoa-bia');

      expect(idsDe(c), ['pessoa-caio']);
      expect((await c.read(perfilDaPessoaProvider(eu.id).future)).conexoes, 1);
      final semAcesso = throwsA(
        isA<ErroDaApi>().having((e) => e.semAcesso, 'semAcesso', isTrue),
      );
      await expectLater(
        c.read(perfilDaPessoaProvider('pessoa-bia').future),
        semAcesso,
      );
      await expectLater(
        c.read(atividadesFeitasProvider('pessoa-bia').future),
        semAcesso,
      );
    },
  );

  test(
    'trocar de conta refaz a lista sem mostrar nenhum amigo da conta anterior',
    () async {
      // eu sou amiga do Caio; a Bia, da Dani
      final api = apiCom(
        conexoes: [(eu.id, 'pessoa-caio'), ('pessoa-bia', 'pessoa-dani')],
      );
      final autenticador = AutenticadorFalso(conta: contaDeTeste);
      final c = containerDeTeste(api, autenticador: autenticador);
      c.listen(perfilAtualProvider, (_, _) {});
      final tela = c.listen(conexoesProvider, (_, _) {});
      expect((await c.read(conexoesProvider.future)).map((p) => p.id), [
        'pessoa-caio',
      ]);
      // a tela da lista fecha antes da troca: o provider fica sem ouvinte, parado com a lista velha
      tela.close();

      await autenticador.sair();
      await ticks();
      api
        ..entrarComo('pessoa-bia')
        ..segurarListarConexoes = Completer<void>();
      await autenticador.entrarComGoogle();
      await ticks();
      expect((await c.read(perfilAtualProvider.future))?.id, 'pessoa-bia');

      // o que a tela mostraria a cada estado, desde que ela volta com a conta nova
      final vistos = <List<String>>[];
      c.listen(
        conexoesProvider,
        (_, estado) => vistos.add([
          for (final p in amigosDaConta(estado) ?? const <Pessoa>[]) p.id,
        ]),
        fireImmediately: true,
      );
      await ticks();
      api.segurarListarConexoes!.complete();
      await c.read(conexoesProvider.future);

      expect(vistos.last, ['pessoa-dani']);
      expect(vistos.expand((ids) => ids), isNot(contains('pessoa-caio')));
    },
  );
}
