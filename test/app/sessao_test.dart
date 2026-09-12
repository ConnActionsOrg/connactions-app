import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/app/sessao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/autenticador_falso.dart';
import '../apoio/fake_api.dart';

// retry nulo: o Riverpod 3 repete provider que falhou (até 10x com backoff), o que esconderia o
// erro e faria o teste esperar segundos.
ProviderContainer montar({
  required AutenticadorFalso autenticador,
  required FakeApi api,
}) {
  final container = ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
      autenticadorProvider.overrideWithValue(autenticador),
      apiProvider.overrideWithValue(api),
    ],
  );
  // sem alguém "observando", o Riverpod pausa a stream por trás do contaProvider e
  // container.read(...future) nunca entrega o primeiro valor (só reproduz com container solto,
  // sem widget: em app real a árvore de widgets já mantém isto vivo).
  container.listen(perfilAtualProvider, (_, _) {});
  return container;
}

void main() {
  test('deslogado: o perfil atual é nulo e a API não é chamada', () async {
    final api = FakeApi();
    final c = montar(autenticador: AutenticadorFalso(), api: api);
    expect(await c.read(perfilAtualProvider.future), isNull);
    expect(api.chamadas, isEmpty);
  });

  test('logado sem perfil na API: a primeira entrada cria o perfil', () async {
    final api = FakeApi();
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    final eu = await c.read(perfilAtualProvider.future);
    expect(eu?.nome, 'Marina Duarte');
    expect(api.chamadas, ['obterEu', 'criarEu']);
  });

  test('logado com perfil: só obtém', () async {
    final api = FakeApi(eu: euDeTeste(handle: 'marina.d'));
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    expect((await c.read(perfilAtualProvider.future))?.handle, 'marina.d');
    expect(api.chamadas, ['obterEu']);
  });

  test('falha de rede vira erro e não é repetida sozinha', () async {
    final api = FakeApi(falhaAoObter: const ErroDeRede('caiu'));
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await expectLater(
      c.read(perfilAtualProvider.future),
      throwsA(isA<ErroDeRede>()),
    );
    expect(api.chamadas, ['obterEu']);
  });

  test('sair zera o perfil', () async {
    final autenticador = AutenticadorFalso(conta: contaDeTeste);
    final c = montar(
      autenticador: autenticador,
      api: FakeApi(eu: euDeTeste()),
    );
    expect(await c.read(perfilAtualProvider.future), isNotNull);

    await autenticador.sair();
    // a troca viaja pelo stream num evento; um tick vazio a deixa chegar ao contaProvider
    await Future<void>.delayed(Duration.zero);

    expect(await c.read(perfilAtualProvider.future), isNull);
  });

  test('definirVisibilidade grava na API e reflete no estado', () async {
    final api = FakeApi(eu: euDeTeste());
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await c.read(perfilAtualProvider.future);

    await c.read(perfilAtualProvider.notifier).definirVisibilidade(false);

    expect(c.read(perfilAtualProvider).value?.atividadesVisiveis, isFalse);
    expect(api.chamadas.last, 'atualizarVisibilidade:false');
  });

  test('se a API recusa, o estado volta e o erro sobe', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoAtualizar: const ErroDeRede('caiu'),
    );
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await c.read(perfilAtualProvider.future);

    await expectLater(
      c.read(perfilAtualProvider.notifier).definirVisibilidade(false),
      throwsA(isA<ErroDeRede>()),
    );
    expect(c.read(perfilAtualProvider).value?.atividadesVisiveis, isTrue);
  });
}
