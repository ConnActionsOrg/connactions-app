import 'package:connactions_app/app/seletor_de_foto.dart';
import 'package:connactions_app/features/atividades/folha_de_origem_da_foto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

void main() {
  OrigemDaFoto? escolhida;
  var fechou = false;

  /// Um botão abre a folha; o resultado fica em `escolhida` quando ela fecha.
  Future<void> abrir(WidgetTester tester) async {
    escolhida = null;
    fechou = false;
    await tester.pumpWidget(
      montar(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              escolhida = await mostrarFolhaDeOrigemDaFoto(context);
              fechou = true;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Escolher da galeria'), findsOneWidget);
  }

  testWidgets('câmera', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle();
    expect(fechou, isTrue);
    expect(escolhida, OrigemDaFoto.camera);
  });

  testWidgets('galeria', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    expect(fechou, isTrue);
    expect(escolhida, OrigemDaFoto.galeria);
  });

  testWidgets('fechar sem escolher devolve null', (tester) async {
    await abrir(tester);
    await tester.tapAt(const Offset(10, 10)); // fora da folha
    await tester.pumpAndSettle();
    expect(fechou, isTrue);
    expect(escolhida, isNull);
  });
}
