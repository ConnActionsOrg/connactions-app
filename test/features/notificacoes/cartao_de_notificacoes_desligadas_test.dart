import 'package:connactions_app/app/notificador.dart';
import 'package:connactions_app/features/perfil/tela_do_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/ciclo_de_vida.dart';
import '../../apoio/erros_sem_dono.dart';
import '../../apoio/notificador_falso.dart';
import '../../apoio/preferencias_em_memoria.dart';

const titulo = 'Notificações desligadas';

Future<void> abrirPerfil(
  WidgetTester tester, {
  required NotificadorFalso notificador,
  bool perguntou = true,
}) async {
  await tester.pumpWidget(
    appDeTeste(
      notificador: notificador,
      preferencias: PreferenciasEmMemoria({
        if (perguntou) 'notificacoes_perguntadas': 'true',
      }),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDoPerfil), findsOneWidget);
  // o corpo renderizou: sem isto, "cartão ausente" passaria também no erro ou no carregando
  expect(find.text('Editar perfil'), findsOneWidget);
}

Future<void> tocarEmAtivar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Ativar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ativar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('negada depois de o Feed perguntar: o cartão', (tester) async {
    await abrirPerfil(
      tester,
      notificador: NotificadorFalso(permissaoAtual: PermissaoDeAviso.negada),
    );

    expect(find.text(titulo), findsOneWidget);
    expect(
      find.text('Você não vai saber quando for a sua vez de propor.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Ativar'), findsOneWidget);
  });

  testWidgets('antes de o Feed perguntar, o Perfil não cobra', (tester) async {
    await abrirPerfil(
      tester,
      notificador: NotificadorFalso(permissaoAtual: PermissaoDeAviso.negada),
      perguntou: false,
    );

    expect(find.text(titulo), findsNothing);
  });

  testWidgets('"Ativar" pede e, continuando negada, abre as configurações', (
    tester,
  ) async {
    final notificador = NotificadorFalso(
      permissaoAtual: PermissaoDeAviso.negada,
      permissaoAoPedir: PermissaoDeAviso.negada,
    );
    await abrirPerfil(tester, notificador: notificador);

    await tocarEmAtivar(tester);

    expect(
      notificador.chamadas.where(
        (c) => c == 'pedirPermissao' || c == 'abrirConfiguracoes',
      ),
      ['pedirPermissao', 'abrirConfiguracoes'],
    );
    expect(find.text(titulo), findsOneWidget);
  });

  testWidgets('"Ativar" com o pedido que lança também abre as configurações', (
    tester,
  ) async {
    final notificador =
        NotificadorFalso(permissaoAtual: PermissaoDeAviso.negada)
          ..falhaAoPedirPermissao = Exception(
            'A request for permissions is running',
          );
    await abrirPerfil(tester, notificador: notificador);

    final soltos = await errosSemDono(() => tocarEmAtivar(tester));

    expect(soltos, isEmpty);
    expect(
      notificador.chamadas.where(
        (c) => c == 'pedirPermissao' || c == 'abrirConfiguracoes',
      ),
      ['pedirPermissao', 'abrirConfiguracoes'],
    );
    expect(find.text(titulo), findsOneWidget);
  });

  testWidgets('as configurações que não abrem viram um aviso na tela', (
    tester,
  ) async {
    final notificador = NotificadorFalso(
      permissaoAtual: PermissaoDeAviso.negada,
      permissaoAoPedir: PermissaoDeAviso.negada,
    )..falhaAoAbrirConfiguracoes = Exception('ActivityNotFoundException');
    await abrirPerfil(tester, notificador: notificador);

    final soltos = await errosSemDono(() => tocarEmAtivar(tester));

    expect(soltos, isEmpty);
    expect(
      find.text('Não consegui abrir as configurações. Tente de novo.'),
      findsOneWidget,
    );

    // o SnackBar arma um Timer de 4 s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    '"Ativar" que concede fecha o cartão sem abrir as configurações',
    (tester) async {
      final notificador = NotificadorFalso(
        permissaoAtual: PermissaoDeAviso.negada,
        permissaoAoPedir: PermissaoDeAviso.concedida,
      );
      await abrirPerfil(tester, notificador: notificador);

      await tocarEmAtivar(tester);

      expect(notificador.chamadas, contains('pedirPermissao'));
      expect(notificador.chamadas, isNot(contains('abrirConfiguracoes')));
      expect(find.text(titulo), findsNothing);
    },
  );

  testWidgets('com a permissão concedida o cartão não aparece', (tester) async {
    await abrirPerfil(
      tester,
      notificador: NotificadorFalso(permissaoAtual: PermissaoDeAviso.concedida),
    );

    expect(find.text(titulo), findsNothing);
  });

  testWidgets('ligada nas configurações, o cartão some ao voltar ao app', (
    tester,
  ) async {
    final notificador = NotificadorFalso(
      permissaoAtual: PermissaoDeAviso.negada,
    );
    await abrirPerfil(tester, notificador: notificador);
    expect(find.text(titulo), findsOneWidget);

    notificador.permissaoAtual = PermissaoDeAviso.concedida;
    await tester.pumpAndSettle();
    expect(
      find.text(titulo),
      findsOneWidget,
      reason: 'sem voltar ao app, ninguém relê a permissão',
    );

    await sairEVoltarAoApp(tester);
    expect(find.text(titulo), findsNothing);
  });
}
