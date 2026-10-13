import 'dart:async';

import 'package:connactions_app/app/app.dart';
import 'package:connactions_app/app/roteador.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Empurra uma rota no app de teste já montado, como um botão faria. O push só resolve quando a
/// tela empilhada fecha, por isso não se espera por ele.
Future<void> irPara(WidgetTester tester, String rota) async {
  final contexto = tester.element(find.byType(AppConnactions));
  unawaited(
    ProviderScope.containerOf(contexto).read(roteadorProvider).push<void>(rota),
  );
  await tester.pumpAndSettle();
}

/// Como o `irPara`, com o `extra` que o botão de origem (o backlog, a Comunidade) passa.
Future<void> irParaComExtra(
  WidgetTester tester,
  String rota,
  Object extra,
) async {
  final contexto = tester.element(find.byType(AppConnactions));
  unawaited(
    ProviderScope.containerOf(
      contexto,
    ).read(roteadorProvider).push<void>(rota, extra: extra),
  );
  await tester.pumpAndSettle();
}
