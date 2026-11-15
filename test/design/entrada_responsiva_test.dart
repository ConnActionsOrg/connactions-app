import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/design/tema.dart';
import 'package:connactions_app/features/entrada/tela_de_entrada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/autenticador_falso.dart';

void main() {
  for (final tamanho in [const Size(320, 568), const Size(412, 915)]) {
    for (final escala in [1.0, 2.0]) {
      testWidgets('entrada acessível em $tamanho com texto $escala', (
        tester,
      ) async {
        tester.view.physicalSize = tamanho;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = AutenticadorFalso();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [autenticadorProvider.overrideWithValue(auth)],
            child: MaterialApp(
              theme: temaClaro(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(escala)),
                child: child!,
              ),
              home: const TelaDeEntrada(),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final botao = find.widgetWithText(FilledButton, 'Entrar com Google');
        await tester.ensureVisible(botao);
        await tester.pumpAndSettle();
        await tester.tap(botao);
        await tester.pumpAndSettle();
        expect(auth.chamadas, contains('entrar'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
