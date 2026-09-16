import 'package:connactions_app/design/widgets/disco_de_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

void main() {
  testWidgets('mostra o emoji num disco do tamanho pedido', (tester) async {
    await tester.pumpWidget(
      montar(const DiscoDeEmoji(emoji: '🌿', tamanho: 72)),
    );
    expect(find.text('🌿'), findsOneWidget);
    expect(tester.getSize(find.byType(DiscoDeEmoji)), const Size(72, 72));
  });
}
