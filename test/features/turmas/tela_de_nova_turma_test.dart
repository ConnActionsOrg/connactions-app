import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:connactions_app/features/turmas/tela_de_nova_turma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';
import '../../apoio/preferencias_em_memoria.dart';

Future<void> abrir(
  WidgetTester tester, {
  FakeApi? api,
  PreferenciasEmMemoria? preferencias,
}) async {
  await tester.pumpWidget(appDeTeste(api: api, preferencias: preferencias));
  await tester.pumpAndSettle();
  await irPara(tester, '/turmas/nova');
  expect(find.byType(TelaDeNovaTurma), findsOneWidget);
}

FilledButton botaoCriar(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Criar turma'),
);

void main() {
  testWidgets('o botão só habilita com nome', (tester) async {
    await abrir(tester);
    expect(botaoCriar(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Rolê da Firma ');
    await tester.pump();
    expect(botaoCriar(tester).onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(botaoCriar(tester).onPressed, isNull);
  });

  testWidgets('cria com o emoji escolhido, torna ativa e volta ao Feed', (
    tester,
  ) async {
    final api = FakeApi(eu: euDeTeste());
    final prefs = PreferenciasEmMemoria();
    await abrir(tester, api: api, preferencias: prefs);

    await tester.tap(find.text('🍕'));
    await tester.enterText(find.byType(TextField), 'Rolê da Firma');
    await tester.pump();
    await tester.tap(find.text('Criar turma'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'criarTurma:Rolê da Firma:🍕');
    expect(find.byType(TelaDeNovaTurma), findsNothing);
    expect(find.byType(TelaDoFeed), findsOneWidget);
    expect(prefs.valores['turma_ativa_id'], api.turmas.single.id);
  });

  testWidgets('falha ao criar avisa e a tela fica', (tester) async {
    final api = FakeApi(eu: euDeTeste())
      ..falhaAoCriarTurma = const ErroDeRede('caiu');
    await abrir(tester, api: api);

    await tester.enterText(find.byType(TextField), 'Rolê da Firma');
    await tester.pump();
    await tester.tap(find.text('Criar turma'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(find.byType(TelaDeNovaTurma), findsOneWidget);

    // o SnackBar arma um Timer de 4s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrir(tester);
    final scaffold = find.descendant(
      of: find.byType(TelaDeNovaTurma),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });
}
