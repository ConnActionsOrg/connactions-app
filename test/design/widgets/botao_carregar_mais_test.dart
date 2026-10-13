import 'dart:async';

import 'package:connactions_app/design/widgets/botao_carregar_mais.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

TextButton botao(WidgetTester tester) =>
    tester.widget<TextButton>(find.byType(TextButton));

void main() {
  testWidgets('desabilita e mostra progresso até responder', (tester) async {
    final resposta = Completer<void>();
    var chamadas = 0;
    await tester.pumpWidget(
      montar(
        BotaoCarregarMais(
          aoCarregar: () {
            chamadas++;
            return resposta.future;
          },
        ),
      ),
    );
    expect(find.text('Carregar mais'), findsOneWidget);

    await tester.tap(find.text('Carregar mais'));
    await tester.pump();

    expect(chamadas, 1);
    expect(botao(tester).onPressed, isNull);
    expect(find.text('Carregar mais'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete();
    await tester.pumpAndSettle();

    expect(botao(tester).onPressed, isNotNull);
    expect(find.text('Carregar mais'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a falha vira aviso e o botão volta', (tester) async {
    await tester.pumpWidget(
      montar(
        BotaoCarregarMais(aoCarregar: () async => throw Exception('caiu')),
      ),
    );

    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(find.text('Algo deu errado. Tente de novo.'), findsOneWidget);
    expect(botao(tester).onPressed, isNotNull);

    // o SnackBar arma um Timer de 4s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
