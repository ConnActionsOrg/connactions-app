import 'package:connactions_app/features/atividades/cartao_de_registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

void main() {
  testWidgets('mostra autor, legenda e a etiqueta Seu quando é meu', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      montar(
        SizedBox(
          width: 200,
          height: 240,
          child: CartaoDeRegistro(
            registro: registroDeTeste(legenda: 'Bolo de milho'),
            meu: true,
            aoTocar: () => toques++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('Bolo de milho'), findsOneWidget);
    expect(find.text('Seu'), findsOneWidget);
    // a foto da rede falha nos testes (400): o cartão fica de pé com o fundo neutro
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(CartaoDeRegistro));
    expect(toques, 1);
  });

  testWidgets('sem legenda e não meu', (tester) async {
    await tester.pumpWidget(
      montar(
        SizedBox(
          width: 200,
          height: 240,
          child: CartaoDeRegistro(
            registro: registroDeTeste(legenda: ''),
            aoTocar: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Seu'), findsNothing);
    expect(find.text('Bia'), findsOneWidget);
  });
}
