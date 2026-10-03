import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'erros_sem_dono.dart';

void main() {
  test('devolve o erro de um Future que ninguém espera', () async {
    final soltos = await errosSemDono(() async {
      unawaited(Future<void>.error(StateError('solto')));
      await Future<void>.delayed(Duration.zero);
    });

    expect(soltos, hasLength(1));
    expect(soltos.single, isA<StateError>());
  });

  test('sem Future solto devolve a lista vazia', () async {
    expect(await errosSemDono(() async {}), isEmpty);
  });

  // o defeito que este teste pega é o teste ficar pendurado, então o prazo é curto
  test(
    'a falha do próprio corpo sobe em vez de pendurar o teste',
    () async {
      await expectLater(
        errosSemDono(() async => throw StateError('falhou')),
        throwsA(isA<StateError>()),
      );
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );
}
