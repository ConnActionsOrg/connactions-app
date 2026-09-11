import 'package:connactions_app/design/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

void main() {
  test('iniciaisDe pega a primeira letra do primeiro e do último nome', () {
    expect(iniciaisDe('Marina Duarte'), 'MD');
    expect(iniciaisDe('Bia'), 'B');
    expect(iniciaisDe('  ana  clara  souza '), 'AS');
    expect(iniciaisDe(''), '?');
  });

  testWidgets('sem foto mostra as iniciais', (tester) async {
    await tester.pumpWidget(
      montar(const Center(child: Avatar(nome: 'Marina Duarte', tamanho: 96))),
    );
    expect(find.text('MD'), findsOneWidget);
  });
}
