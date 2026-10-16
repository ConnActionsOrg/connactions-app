import 'package:connactions_app/features/perfil/codigo_em_destaque.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

/// Quantas linhas o texto ocupou: uma caixa por trecho, e cada linha tem o seu topo.
int linhasDe(WidgetTester tester, String texto) => tester
    .renderObject<RenderParagraph>(find.text(texto))
    .getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: texto.length),
    )
    .map((caixa) => caixa.top)
    .toSet()
    .length;

Widget naLargura(double largura, double escala) => montar(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(escala)),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: largura,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [CodigoEmDestaque('ABCD2345')],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'com a fonte do Android no dobro, o código fica numa linha só e dentro do cartão',
    (tester) async {
      // 280 px é o que sobra num celular de 360 px, tirando a margem da tela e a do cartão
      await tester.pumpWidget(naLargura(280, 2));

      expect(linhasDe(tester, 'ABCD2345'), 1);
      expect(
        tester.getRect(find.text('ABCD2345')).right,
        lessThanOrEqualTo(280),
      );
    },
  );

  testWidgets('com a fonte normal, o código fica do tamanho natural', (
    tester,
  ) async {
    await tester.pumpWidget(naLargura(280, 1));

    final natural = tester.renderObject<RenderParagraph>(find.text('ABCD2345'));
    expect(linhasDe(tester, 'ABCD2345'), 1);
    // getRect é a caixa na tela, já com a escala de um FittedBox; o size do parágrafo é o natural
    expect(
      tester.getRect(find.text('ABCD2345')).width,
      moreOrLessEquals(natural.size.width),
    );
  });
}
