import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/features/perfil/tela_de_editar_perfil.dart';
import 'package:connactions_app/features/perfil/tela_do_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';

Future<void> abrirEdicao(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Editar perfil'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDeEditarPerfil), findsOneWidget);
}

Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

String textoDo(WidgetTester tester, String rotulo) =>
    tester.widget<TextField>(campo(rotulo)).controller!.text;

FilledButton botaoSalvar(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar'));

void main() {
  testWidgets('abre com os valores atuais e Salvar desabilitado', (
    tester,
  ) async {
    await abrirEdicao(
      tester,
      FakeApi(
        eu: euDeTeste(nome: 'Marina Duarte', handle: 'marina.d', bio: 'Oi'),
      ),
    );

    expect(textoDo(tester, 'Nome'), 'Marina Duarte');
    expect(textoDo(tester, '@handle'), 'marina.d');
    expect(textoDo(tester, 'Bio'), 'Oi');
    expect(botaoSalvar(tester).onPressed, isNull);
  });

  testWidgets('salva só o que mudou, volta ao Perfil e avisa', (tester) async {
    final api = FakeApi(eu: euDeTeste());
    await abrirEdicao(tester, api);

    await tester.enterText(campo('Nome'), 'Marina D.');
    await tester.pump();
    expect(botaoSalvar(tester).onPressed, isNotNull);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'atualizarEu:{"nome":"Marina D."}');
    expect(find.byType(TelaDeEditarPerfil), findsNothing);
    expect(find.byType(TelaDoPerfil), findsOneWidget);
    expect(find.text('Marina D.'), findsOneWidget);
    expect(find.text('Perfil atualizado'), findsOneWidget);

    // o SnackBar arma um Timer de 4s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('handle digitado em maiúsculas vira minúsculas', (tester) async {
    final api = FakeApi(eu: euDeTeste());
    await abrirEdicao(tester, api);

    await tester.enterText(campo('@handle'), 'Marina.DD');
    await tester.pump();
    expect(textoDo(tester, '@handle'), 'marina.dd');

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(api.chamadas.last, 'atualizarEu:{"handle":"marina.dd"}');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('handle em uso vira erro no campo e a tela fica', (tester) async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoAtualizar: const ErroDaApi(
        status: 422,
        codigo: 'handle_em_uso',
        mensagem: 'Esse @handle já é de outra pessoa.',
      ),
    );
    await abrirEdicao(tester, api);

    await tester.enterText(campo('@handle'), 'outra.pessoa');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Esse @handle já é de outra pessoa.'), findsOneWidget);
    expect(find.byType(TelaDeEditarPerfil), findsOneWidget);
    expect(textoDo(tester, '@handle'), 'outra.pessoa');
  });

  testWidgets('falha de rede avisa e mantém o rascunho', (tester) async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoAtualizar: const ErroDeRede('caiu'),
    );
    await abrirEdicao(tester, api);

    await tester.enterText(campo('Bio'), 'Colecionando risadas');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(textoDo(tester, 'Bio'), 'Colecionando risadas');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Salvar exige nome e handle com três ou mais caracteres', (
    tester,
  ) async {
    await abrirEdicao(tester, FakeApi(eu: euDeTeste()));

    await tester.enterText(campo('Nome'), '   ');
    await tester.pump();
    expect(botaoSalvar(tester).onPressed, isNull);

    await tester.enterText(campo('Nome'), 'Marina Duarte');
    await tester.enterText(campo('@handle'), 'ab');
    await tester.pump();
    expect(botaoSalvar(tester).onPressed, isNull);
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrirEdicao(tester, FakeApi(eu: euDeTeste()));
    final scaffold = find.descendant(
      of: find.byType(TelaDeEditarPerfil),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });
}
