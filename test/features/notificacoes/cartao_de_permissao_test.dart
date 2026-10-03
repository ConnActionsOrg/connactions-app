import 'package:connactions_app/app/notificador.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/notificador_falso.dart';
import '../../apoio/preferencias_em_memoria.dart';

const pergunta = 'Quer saber quando for a sua vez?';
const explicacao =
    'O ConnActions avisa quando for a sua vez de propor, quando alguém lançar '
    'uma atividade ou postar um registro, e no último dia do prazo.';

Future<void> abrirFeed(
  WidgetTester tester, {
  required NotificadorFalso notificador,
  required PreferenciasEmMemoria preferencias,
  bool comTurma = true,
}) async {
  await tester.pumpWidget(
    appDeTeste(
      api: FakeApi(eu: euDeTeste(), turmas: [if (comTurma) turmaDeTeste()]),
      notificador: notificador,
      preferencias: preferencias,
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(TelaDoFeed), findsOneWidget);
}

/// Anota se a marca já estava gravada quando a caixa do sistema abriu: a caixa tira o app do
/// primeiro plano, e a releitura da volta tem de encontrar a marca.
class _NotificadorQueOlhaAMarca extends NotificadorFalso {
  _NotificadorQueOlhaAMarca(this.preferencias)
    : super(
        permissaoAtual: PermissaoDeAviso.negada,
        permissaoAoPedir: PermissaoDeAviso.negada,
      );

  final PreferenciasEmMemoria preferencias;
  String? marcaAoPedir;

  @override
  Future<PermissaoDeAviso> pedirPermissao() {
    marcaAoPedir = preferencias.valores['notificacoes_perguntadas'];
    return super.pedirPermissao();
  }
}

void main() {
  testWidgets('com turma, permissão negada e sem a marca: o cartão', (
    tester,
  ) async {
    await abrirFeed(
      tester,
      notificador: NotificadorFalso(permissaoAtual: PermissaoDeAviso.negada),
      preferencias: PreferenciasEmMemoria(),
    );

    expect(find.text(pergunta), findsOneWidget);
    expect(find.text(explicacao), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Agora não'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ativar'), findsOneWidget);
  });

  testWidgets('"Agora não" marca, some e não volta na abertura seguinte', (
    tester,
  ) async {
    final notificador = NotificadorFalso(
      permissaoAtual: PermissaoDeAviso.negada,
    );
    final preferencias = PreferenciasEmMemoria();
    await abrirFeed(
      tester,
      notificador: notificador,
      preferencias: preferencias,
    );

    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();

    expect(find.text(pergunta), findsNothing);
    expect(preferencias.valores['notificacoes_perguntadas'], 'true');
    expect(notificador.chamadas, isNot(contains('pedirPermissao')));

    // o app fechado e aberto de novo, com o que ficou no aparelho
    await tester.pumpWidget(const SizedBox.shrink());
    await abrirFeed(
      tester,
      notificador: NotificadorFalso(permissaoAtual: PermissaoDeAviso.negada),
      preferencias: preferencias,
    );
    expect(find.text(pergunta), findsNothing);
  });

  testWidgets('"Ativar" marca antes de pedir, pede e o cartão some', (
    tester,
  ) async {
    final preferencias = PreferenciasEmMemoria();
    final notificador = _NotificadorQueOlhaAMarca(preferencias);
    await abrirFeed(
      tester,
      notificador: notificador,
      preferencias: preferencias,
    );

    await tester.tap(find.text('Ativar'));
    await tester.pumpAndSettle();

    expect(notificador.chamadas, contains('pedirPermissao'));
    expect(notificador.marcaAoPedir, 'true');
    // recusou na caixa, e mesmo assim o Feed não pergunta de novo: daqui em diante é com o Perfil
    expect(find.text(pergunta), findsNothing);
  });

  testWidgets('com a permissão já concedida não aparece, e a marca é gravada', (
    tester,
  ) async {
    final notificador = NotificadorFalso(
      permissaoAtual: PermissaoDeAviso.concedida,
    );
    final preferencias = PreferenciasEmMemoria();
    await abrirFeed(
      tester,
      notificador: notificador,
      preferencias: preferencias,
    );

    expect(find.text(pergunta), findsNothing);
    expect(preferencias.valores['notificacoes_perguntadas'], 'true');
    expect(notificador.chamadas, isNot(contains('pedirPermissao')));
  });

  testWidgets('sem turma o cartão não aparece', (tester) async {
    await abrirFeed(
      tester,
      notificador: NotificadorFalso(permissaoAtual: PermissaoDeAviso.negada),
      preferencias: PreferenciasEmMemoria(),
      comTurma: false,
    );

    expect(find.text('Nenhuma turma por aqui ainda'), findsOneWidget);
    expect(find.text(pergunta), findsNothing);
  });
}
