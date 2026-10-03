import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/app/sessao.dart';
import 'package:connactions_app/features/notificacoes/cadastro_do_aparelho.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/autenticador_falso.dart';
import '../../apoio/erros_sem_dono.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/notificador_falso.dart';

ProviderContainer montar({
  required FakeApi api,
  required NotificadorFalso notificador,
  AutenticadorFalso? autenticador,
}) {
  final container = ProviderContainer.test(
    overrides: [
      autenticadorProvider.overrideWithValue(
        autenticador ?? AutenticadorFalso(conta: contaDeTeste),
      ),
      apiProvider.overrideWithValue(api),
      notificadorProvider.overrideWithValue(notificador),
    ],
  );
  // sem ouvinte o Riverpod pausa a cadeia conta → perfil → cadastro e nada acontece
  container.listen(cadastroDoAparelhoProvider, (_, _) {});
  return container;
}

List<String> cadastros(FakeApi api) =>
    api.chamadas.where((c) => c.startsWith('registrarDispositivo')).toList();

/// Deixa chegar o que viaja por stream (token novo, troca de conta) e a chamada que ele dispara.
Future<void> assentar() => Future<void>.delayed(Duration.zero);

void main() {
  test('deslogado não pede token nem cadastra', () async {
    final api = FakeApi();
    final notificador = NotificadorFalso();
    final c = montar(
      api: api,
      notificador: notificador,
      autenticador: AutenticadorFalso(),
    );

    await c.read(cadastroDoAparelhoProvider.future);

    expect(notificador.chamadas, isEmpty);
    expect(api.chamadas, isEmpty);
  });

  test('não cadastra enquanto o perfil não chega', () async {
    final api = FakeApi(eu: euDeTeste())..segurarObterEu = Completer<void>();
    final notificador = NotificadorFalso();
    final c = montar(api: api, notificador: notificador);
    await assentar();
    await assentar();

    expect(notificador.chamadas, isEmpty);
    expect(cadastros(api), isEmpty);

    api.segurarObterEu!.complete();
    await c.read(perfilAtualProvider.future);
    await c.read(cadastroDoAparelhoProvider.future);

    expect(api.chamadas, ['obterEu', 'registrarDispositivo:token-fcm-1']);
  });

  test('no primeiro login cadastra só depois do POST /eu', () async {
    final api = FakeApi(); // sem perfil: o GET /eu dá 403 e o app cria
    final c = montar(api: api, notificador: NotificadorFalso());

    await c.read(perfilAtualProvider.future);
    await c.read(cadastroDoAparelhoProvider.future);

    expect(api.chamadas, [
      'obterEu',
      'criarEu',
      'registrarDispositivo:token-fcm-1',
    ]);
  });

  test('o token que o Firebase renovou é cadastrado de novo', () async {
    final api = FakeApi(eu: euDeTeste());
    final notificador = NotificadorFalso();
    final c = montar(api: api, notificador: notificador);
    await c.read(perfilAtualProvider.future);
    await c.read(cadastroDoAparelhoProvider.future);

    notificador.renovarToken('token-fcm-2');
    await assentar();

    expect(cadastros(api), [
      'registrarDispositivo:token-fcm-1',
      'registrarDispositivo:token-fcm-2',
    ]);
  });

  test(
    'a API que falha não quebra nada, e o token novo ainda cadastra',
    () async {
      final api = FakeApi(
        eu: euDeTeste(),
        falhaAoRegistrarDispositivo: const ErroDeRede('caiu'),
      );
      final notificador = NotificadorFalso();
      final c = montar(api: api, notificador: notificador);
      await c.read(perfilAtualProvider.future);

      await expectLater(c.read(cadastroDoAparelhoProvider.future), completes);

      api.falhaAoRegistrarDispositivo = null;
      notificador.renovarToken('token-fcm-2');
      await assentar();
      expect(cadastros(api), [
        'registrarDispositivo:token-fcm-1',
        'registrarDispositivo:token-fcm-2',
      ]);
    },
  );

  test('a API que falha com o token renovado não solta erro', () async {
    final api = FakeApi(eu: euDeTeste());
    final notificador = NotificadorFalso();

    final soltos = await errosSemDono(() async {
      final c = montar(api: api, notificador: notificador);
      await c.read(perfilAtualProvider.future);
      await c.read(cadastroDoAparelhoProvider.future);

      api.falhaAoRegistrarDispositivo = const ErroDeRede('caiu');
      notificador.renovarToken('token-fcm-2');
      await assentar();
    });

    // o Stream.listen descarta o Future de cadastrar: a falha tem de morrer lá dentro
    expect(soltos, isEmpty);
    expect(cadastros(api), [
      'registrarDispositivo:token-fcm-1',
      'registrarDispositivo:token-fcm-2',
    ]);
  });

  test('o Firebase que não dá o token não quebra nada', () async {
    final api = FakeApi(eu: euDeTeste());
    final notificador = NotificadorFalso()
      ..falhaAoLerToken = Exception('SERVICE_NOT_AVAILABLE');
    final c = montar(api: api, notificador: notificador);
    await c.read(perfilAtualProvider.future);

    await expectLater(c.read(cadastroDoAparelhoProvider.future), completes);
    expect(cadastros(api), isEmpty);
  });

  test(
    'depois de sair, o token renovado não vai para a conta que saiu',
    () async {
      final autenticador = AutenticadorFalso(conta: contaDeTeste);
      final api = FakeApi(eu: euDeTeste());
      final notificador = NotificadorFalso();
      final c = montar(
        api: api,
        notificador: notificador,
        autenticador: autenticador,
      );
      await c.read(perfilAtualProvider.future);
      await c.read(cadastroDoAparelhoProvider.future);

      await autenticador.sair();
      await assentar();
      expect(await c.read(perfilAtualProvider.future), isNull);
      await c.read(cadastroDoAparelhoProvider.future);
      notificador.renovarToken('token-fcm-2');
      await assentar();

      expect(cadastros(api), ['registrarDispositivo:token-fcm-1']);
    },
  );

  testWidgets('o app aberto e logado cadastra o aparelho', (tester) async {
    final api = FakeApi(eu: euDeTeste());
    await tester.pumpWidget(appDeTeste(api: api));
    await tester.pumpAndSettle();

    expect(cadastros(api), ['registrarDispositivo:token-fcm-1']);
    expect(api.plataformas, ['android']);
  });
}
