import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Navega pelo conteúdo real, inclusive quando um item ainda não foi construído
/// pela lista. Os testes não dependem da altura dos cabeçalhos editoriais.
Future<void> ver(WidgetTester tester, Finder alvo) async {
  if (alvo.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      alvo,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(alvo.first);
  await tester.pump();
}

Future<void> tocar(
  WidgetTester tester,
  Finder alvo, {
  bool warnIfMissed = true,
}) async {
  await ver(tester, alvo);
  await tester.tap(alvo, warnIfMissed: warnIfMissed);
}
