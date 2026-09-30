import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/alteracoes_do_eu.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/app/sessao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/autenticador_falso.dart';
import '../apoio/fake_api.dart';

ProviderContainer montar({
  required AutenticadorFalso autenticador,
  required FakeApi api,
}) {
  final container = ProviderContainer.test(
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

  test('ErroDaApi que não é perfil_nao_criado sobe sem criar perfil', () async {
    final api = FakeApi(
      falhaAoObter: const ErroDaApi(
        status: 500,
        codigo: 'erro_interno',
        mensagem: 'Algo deu errado.',
      ),
    );
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await expectLater(
      c.read(perfilAtualProvider.future),
      throwsA(isA<ErroDaApi>()),
    );
    expect(api.chamadas, ['obterEu']);
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
    expect(api.chamadas.last, 'atualizarEu:{"atividades_visiveis":false}');
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

  test('atualizar grava só o que mudou e reflete no estado', () async {
    final api = FakeApi(eu: euDeTeste());
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await c.read(perfilAtualProvider.future);

    final salvo = await c
        .read(perfilAtualProvider.notifier)
        .atualizar(const AlteracoesDoEu(nome: 'Marina D.'));

    expect(salvo.nome, 'Marina D.');
    expect(c.read(perfilAtualProvider).value?.nome, 'Marina D.');
    expect(c.read(perfilAtualProvider).value?.handle, 'marina.d');
    expect(api.chamadas.last, 'atualizarEu:{"nome":"Marina D."}');
  });

  test('atualizar que a API recusa sobe sem mexer no estado', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoAtualizar: const ErroDaApi(
        status: 422,
        codigo: 'handle_em_uso',
        mensagem: 'Esse @handle já é de outra pessoa.',
      ),
    );
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await c.read(perfilAtualProvider.future);

    await expectLater(
      c
          .read(perfilAtualProvider.notifier)
          .atualizar(const AlteracoesDoEu(handle: 'outra.pessoa')),
      throwsA(
        isA<ErroDaApi>().having((e) => e.handleEmUso, 'handleEmUso', isTrue),
      ),
    );
    expect(c.read(perfilAtualProvider).value?.handle, 'marina.d');
  });

  test('trocarFoto grava o Eu devolvido', () async {
    final api = FakeApi(eu: euDeTeste());
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await c.read(perfilAtualProvider.future);

    final eu = await c
        .read(perfilAtualProvider.notifier)
        .trocarFoto(fotoDeTeste());

    expect(eu.fotoUrl, 'http://midia.local/midia/perfis/foto.jpg');
    expect(c.read(perfilAtualProvider).value?.fotoUrl, eu.fotoUrl);
    expect(api.chamadas.last, 'trocarFoto:foto.jpg');
  });

  test('trocarFoto espera o perfil assentar antes de enviar', () async {
    final api = FakeApi(eu: euDeTeste())..segurarObterEu = Completer<void>();
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );

    final futuro = c
        .read(perfilAtualProvider.notifier)
        .trocarFoto(fotoDeTeste());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(api.chamadas, isNot(contains('trocarFoto:foto.jpg')));

    api.segurarObterEu!.complete();
    final eu = await futuro;

    expect(
      api.chamadas.indexOf('obterEu'),
      lessThan(api.chamadas.indexOf('trocarFoto:foto.jpg')),
    );
    expect(c.read(perfilAtualProvider).value?.fotoUrl, eu.fotoUrl);
  });

  test('trocarFoto depois de recarga do perfil que falhou chama a API', () async {
    final api = FakeApi(eu: euDeTeste());
    final c = montar(
      autenticador: AutenticadorFalso(conta: contaDeTeste),
      api: api,
    );
    await c.read(perfilAtualProvider.future);
    // o erro da recarga sem rede fica junto do perfil que já estava; a rede volta antes da ação
    api.falhaAoObter = const ErroDeRede('caiu');
    await expectLater(
      c.refresh(perfilAtualProvider.future),
      throwsA(isA<ErroDeRede>()),
    );
    api.falhaAoObter = null;

    final eu = await c
        .read(perfilAtualProvider.notifier)
        .trocarFoto(fotoDeTeste());

    expect(api.chamadas.last, 'trocarFoto:foto.jpg');
    expect(c.read(perfilAtualProvider).value?.fotoUrl, eu.fotoUrl);
  });
}
