import 'package:connactions_app/design/widgets/etiqueta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

Color fundoDa(WidgetTester tester, String texto) {
  final caixa = tester.widget<Container>(
    find.ancestor(of: find.text(texto), matching: find.byType(Container)).first,
  );
  return (caixa.decoration! as BoxDecoration).color!;
}

void main() {
  // Constantes congeladas de propósito: se o token mudar, este teste cai.
  testWidgets('cada tom tem o fundo do DESIGN.md', (tester) async {
    await tester.pumpWidget(
      montar(
        const Column(
          children: [
            Etiqueta(texto: 'Ativa'),
            Etiqueta(texto: 'Vez', tom: TomDaEtiqueta.ambar),
            Etiqueta(texto: 'Feita', tom: TomDaEtiqueta.salvia),
          ],
        ),
      ),
    );
    expect(fundoDa(tester, 'Ativa'), const Color(0xFFFFDBD1));
    expect(fundoDa(tester, 'Vez'), const Color(0xFFFFDDB6));
    expect(fundoDa(tester, 'Feita'), const Color(0xFFCDEAD0));
  });
}
