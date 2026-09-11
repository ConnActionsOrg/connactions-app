import 'package:connactions_app/design/tema.dart';
import 'package:connactions_app/design/widgets/cabecalho.dart';
import 'package:connactions_app/design/widgets/marca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('o cabeçalho traz a marca e o nome do app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClaro(),
        home: const Scaffold(appBar: Cabecalho(), body: SizedBox()),
      ),
    );

    expect(find.byType(Marca), findsOneWidget);
    expect(find.text('ConnActions'), findsOneWidget);
  });
}
