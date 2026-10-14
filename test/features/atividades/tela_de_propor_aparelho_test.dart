import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/features/atividades/tela_de_propor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();
final agora = DateTime(2026, 9, 29, 12);

final trilha = ideiaDeTeste(
  id: 'i2',
  titulo: 'Trilha',
  descricao: 'Subir o morro.',
  autor: bia,
);

FakeApi apiCom({
  List<Ideia> ideias = const [],
  List<AtividadeDaComunidade> comunidade = const [],
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  ideiasPor: {'turma-1': ideias},
  comunidade: comunidade,
);

/// Só o que está dentro do Propor: o Feed por baixo também tem "Comunidade" na barra de abas.
Finder naTela(String texto) =>
    find.descendant(of: find.byType(TelaDePropor), matching: find.text(texto));

/// Do tamanho do SM-S942B (1080x2340 px, ~411 dp) ou de um celular menor.
void telaDe(WidgetTester tester, {required double largura, double? fonte}) {
  tester.view.devicePixelRatio = 2.625;
  tester.view.physicalSize = Size(largura * 2.625, 2340);
  addTearDown(tester.view.reset);
  if (fonte != null) {
    tester.platformDispatcher.textScaleFactorTestValue = fonte;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
}

Future<void> abrirPeloFeed(WidgetTester tester) async {
  await tester.pumpWidget(appDeTeste(api: apiCom(), agora: agora));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Propor atividade'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDePropor), findsOneWidget);
}

/// O `EditableText` do título, que é quem guarda o foco.
bool tituloComFoco(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextField, 'Nome da atividade'),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

Future<void> irParaAba(WidgetTester tester, String aba) async {
  await tester.ensureVisible(naTela(aba));
  await tester.pumpAndSettle();
  await tester.tap(naTela(aba));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('foco do título', () {
    testWidgets('(a) sem origem, o título ganha o foco e o teclado', (
      tester,
    ) async {
      await abrirPeloFeed(tester);

      expect(tituloComFoco(tester), isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('(b) com origem no extra, o título não ganha o foco', (
      tester,
    ) async {
      await tester.pumpWidget(
        appDeTeste(
          api: apiCom(ideias: [trilha]),
          agora: agora,
        ),
      );
      await tester.pumpAndSettle();

      await irParaComExtra(tester, '/turmas/turma-1/propor', trilha);

      expect(find.byType(TelaDePropor), findsOneWidget);
      expect(tituloComFoco(tester), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('(c) escolher uma origem nas abinhas e voltar não dá o foco', (
      tester,
    ) async {
      await tester.pumpWidget(
        appDeTeste(
          api: apiCom(ideias: [trilha]),
          agora: agora,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Propor atividade'));
      await tester.pumpAndSettle();
      await irParaAba(tester, 'Backlog');

      await tester.tap(find.text('Propor esta'));
      await tester.pumpAndSettle();

      expect(find.text('Ideia de Bia'), findsOneWidget);
      expect(tituloComFoco(tester), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('(d) sair da abinha "Do zero" e voltar não dá o foco', (
      tester,
    ) async {
      await abrirPeloFeed(tester);
      await irParaAba(tester, 'Backlog');

      await irParaAba(tester, 'Do zero');

      expect(tituloComFoco(tester), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });

  group('rótulo das abinhas em uma linha', () {
    for (final largura in [411.0, 360.0]) {
      for (final fonte in [1.0, 1.3]) {
        testWidgets('${largura}dp, fonte ${fonte}x', (tester) async {
          telaDe(tester, largura: largura, fonte: fonte);
          await abrirPeloFeed(tester);

          // "Backlog" é a palavra curta, que nunca quebra: a altura de uma linha
          final umaLinha = tester.getSize(naTela('Backlog')).height;
          for (final rotulo in ['Do zero', 'Backlog', 'Comunidade']) {
            expect(
              tester.getSize(naTela(rotulo)).height,
              lessThanOrEqualTo(umaLinha * 1.3),
              reason: '"$rotulo" quebrou em duas linhas',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
