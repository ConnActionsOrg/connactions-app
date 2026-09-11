import 'package:connactions_app/design/widgets/marca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

void main() {
  testWidgets('a marca é desenhada no tamanho pedido e tem nome acessível', (
    tester,
  ) async {
    await tester.pumpWidget(montar(const Center(child: Marca(tamanho: 64))));

    final pintura = find.descendant(
      of: find.byType(Marca),
      matching: find.byType(CustomPaint),
    );
    expect(pintura, findsOneWidget);
    expect(tester.getSize(pintura), const Size(64, 64));

    final semantica = tester.widget<Semantics>(
      find.descendant(of: find.byType(Marca), matching: find.byType(Semantics)),
    );
    expect(semantica.properties.label, 'ConnActions');
  });
}
