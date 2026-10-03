import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/app/sessao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/autenticador_falso.dart';
import '../apoio/fake_api.dart';
import '../apoio/notificador_falso.dart';

/// Os três dublês anotam no mesmo caderno: só assim a ordem entre eles fica provada.
class _ApiQueAnota extends FakeApi {
  _ApiQueAnota(this.caderno) : super(eu: euDeTeste());

  final List<String> caderno;

  @override
  Future<void> removerDispositivo(String token) {
    caderno.add('removerDispositivo:$token');
    return super.removerDispositivo(token);
  }
}

class _NotificadorQueAnota extends NotificadorFalso {
  _NotificadorQueAnota(this.caderno);

  final List<String> caderno;

  @override
  Future<String?> token() {
    caderno.add('token');
    return super.token();
  }

  @override
  Future<void> apagarToken() {
    caderno.add('apagarToken');
    return super.apagarToken();
  }
}

class _AutenticadorQueAnota extends AutenticadorFalso {
  _AutenticadorQueAnota(this.caderno) : super(conta: contaDeTeste);

  final List<String> caderno;

  @override
  Future<void> sair() {
    caderno.add('sair');
    return super.sair();
  }
}

/// O DELETE que nunca volta, como a API atrás de uma rede que caiu no meio da chamada.
class _ApiQueNaoResponde extends FakeApi {
  _ApiQueNaoResponde() : super(eu: euDeTeste());

  @override
  Future<void> removerDispositivo(String token) => Completer<void>().future;
}

/// O logout que não acontece: a única falha que a saída deixa subir.
class _AutenticadorQueFalhaAoSair extends AutenticadorFalso {
  _AutenticadorQueFalhaAoSair(this.falha) : super(conta: contaDeTeste);

  final Object falha;

  @override
  Future<void> sair() async => throw falha;
}

void main() {
  test('tira o aparelho da API e do Firebase antes de deslogar', () async {
    final caderno = <String>[];

    await sairDaConta(
      notificador: _NotificadorQueAnota(caderno),
      api: _ApiQueAnota(caderno),
      autenticador: _AutenticadorQueAnota(caderno),
    );

    expect(caderno, [
      'token',
      'removerDispositivo:token-fcm-1',
      'apagarToken',
      'sair',
    ]);
  });

  test('o DELETE que falha não impede a saída', () async {
    final caderno = <String>[];
    final api = _ApiQueAnota(caderno)
      ..falhaAoRemoverDispositivo = const ErroDeRede('caiu');

    await sairDaConta(
      notificador: _NotificadorQueAnota(caderno),
      api: api,
      autenticador: _AutenticadorQueAnota(caderno),
    );

    expect(caderno, [
      'token',
      'removerDispositivo:token-fcm-1',
      'apagarToken',
      'sair',
    ]);
  });

  test('sem token no Firebase não há DELETE, e a saída segue', () async {
    final caderno = <String>[];

    await sairDaConta(
      notificador: _NotificadorQueAnota(caderno)..tokenAtual = null,
      api: _ApiQueAnota(caderno),
      autenticador: _AutenticadorQueAnota(caderno),
    );

    expect(caderno, ['token', 'apagarToken', 'sair']);
  });

  test(
    'o Firebase que falha ao dar ou ao apagar o token não impede a saída',
    () async {
      final caderno = <String>[];
      final notificador = _NotificadorQueAnota(caderno)
        ..falhaAoLerToken = Exception('SERVICE_NOT_AVAILABLE')
        ..falhaAoApagarToken = Exception('SERVICE_NOT_AVAILABLE');

      await sairDaConta(
        notificador: notificador,
        api: _ApiQueAnota(caderno),
        autenticador: _AutenticadorQueAnota(caderno),
      );

      expect(caderno, ['token', 'apagarToken', 'sair']);
    },
  );

  test(
    'o logout que falha sobe: a pessoa segue logada e precisa saber',
    () async {
      final falha = Exception('SERVICE_NOT_AVAILABLE');

      await expectLater(
        sairDaConta(
          notificador: NotificadorFalso(),
          api: FakeApi(eu: euDeTeste()),
          autenticador: _AutenticadorQueFalhaAoSair(falha),
        ),
        throwsA(same(falha)),
      );
    },
  );

  // testWidgets pelo relógio falso: o prazo de 5 s passa sem esperar 5 s de verdade
  testWidgets('o DELETE que nunca responde segura a saída 5 s, não mais', (
    tester,
  ) async {
    final autenticador = AutenticadorFalso(conta: contaDeTeste);
    unawaited(
      sairDaConta(
        notificador: NotificadorFalso(),
        api: _ApiQueNaoResponde(),
        autenticador: autenticador,
      ),
    );

    await tester.pump(const Duration(milliseconds: 4900));
    expect(autenticador.chamadas, isEmpty);

    await tester.pump(const Duration(milliseconds: 100));
    expect(autenticador.chamadas, ['sair']);
  });

  testWidgets(
    'o Firebase que não responde ao apagar o token também solta em 5 s',
    (tester) async {
      final autenticador = AutenticadorFalso(conta: contaDeTeste);
      final notificador = NotificadorFalso()
        ..segurarApagarToken = Completer<void>();
      unawaited(
        sairDaConta(
          notificador: notificador,
          api: FakeApi(eu: euDeTeste()),
          autenticador: autenticador,
        ),
      );

      await tester.pump(const Duration(milliseconds: 4900));
      expect(autenticador.chamadas, isEmpty);

      await tester.pump(const Duration(milliseconds: 100));
      expect(autenticador.chamadas, ['sair']);
    },
  );
}
