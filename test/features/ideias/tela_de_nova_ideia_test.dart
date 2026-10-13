import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/features/ideias/tela_de_nova_ideia.dart';
import 'package:connactions_app/features/ideias/tela_do_backlog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

FakeApi apiCom() => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
);

/// Pelo backlog, como o app: assim "voltar" cai de volta nele.
Future<void> abrirNovaIdeia(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
  await irPara(tester, '/turmas/turma-1/ideias');
  await tester.tap(find.text('Nova ideia'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDeNovaIdeia), findsOneWidget);
}

Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

FilledButton botaoGuardar(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Guardar ideia'),
);

void main() {
  testWidgets('o botão só habilita com título', (tester) async {
    await abrirNovaIdeia(tester, apiCom());
    expect(botaoGuardar(tester).onPressed, isNull);

    await tester.enterText(campo('Nome da ideia'), '  Noite de pizza ');
    await tester.pump();
    expect(botaoGuardar(tester).onPressed, isNotNull);

    await tester.enterText(campo('Nome da ideia'), '   ');
    await tester.pump();
    expect(botaoGuardar(tester).onPressed, isNull);
  });

  testWidgets('guarda, volta ao backlog com a ideia e avisa', (tester) async {
    final api = apiCom();
    await abrirNovaIdeia(tester, api);

    await tester.enterText(campo('Nome da ideia'), '  Noite de pizza ');
    await tester.enterText(campo('Como seria?'), 'Cada um traz um recheio.');
    await tester.pump();
    await tester.tap(find.text('Guardar ideia'));
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('criarIdeia:turma-1:Noite de pizza'));
    expect(
      api.ideiasPor['turma-1']!.single.descricao,
      'Cada um traz um recheio.',
    );
    expect(find.byType(TelaDeNovaIdeia), findsNothing);
    expect(find.byType(TelaDoBacklog), findsOneWidget);
    expect(find.text('Noite de pizza'), findsOneWidget);
    expect(find.text('Ideia guardada'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('o 409 de backlog cheio avisa e o rascunho fica', (tester) async {
    final api = apiCom()
      ..falhaAoCriarIdeia = const ErroDaApi(
        status: 409,
        codigo: 'backlog_cheio',
        mensagem:
            'Você já tem 5 ideias guardadas nesta turma. Use ou apague uma para guardar outra.',
      );
    await abrirNovaIdeia(tester, api);

    await tester.enterText(campo('Nome da ideia'), 'Noite de pizza');
    await tester.enterText(campo('Como seria?'), 'Cada um traz um recheio.');
    await tester.pump();
    await tester.tap(find.text('Guardar ideia'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Você já tem 5 ideias guardadas nesta turma. Use ou apague uma para guardar outra.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TelaDeNovaIdeia), findsOneWidget);
    expect(
      tester.widget<TextField>(campo('Nome da ideia')).controller!.text,
      'Noite de pizza',
    );
    expect(
      tester.widget<TextField>(campo('Como seria?')).controller!.text,
      'Cada um traz um recheio.',
    );
    expect(botaoGuardar(tester).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('o 422 também avisa e a tela fica', (tester) async {
    final api = apiCom()
      ..falhaAoCriarIdeia = const ErroDaApi(
        status: 422,
        codigo: 'dados_invalidos',
        mensagem: 'O título precisa ter de 1 a 80 caracteres.',
      );
    await abrirNovaIdeia(tester, api);

    await tester.enterText(campo('Nome da ideia'), 'x');
    await tester.pump();
    await tester.tap(find.text('Guardar ideia'));
    await tester.pumpAndSettle();

    expect(
      find.text('O título precisa ter de 1 a 80 caracteres.'),
      findsOneWidget,
    );
    expect(find.byType(TelaDeNovaIdeia), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrirNovaIdeia(tester, apiCom());
    final scaffold = find.descendant(
      of: find.byType(TelaDeNovaIdeia),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });
}
