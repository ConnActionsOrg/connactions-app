import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:connactions_app/features/turmas/convite.dart';
import 'package:connactions_app/features/turmas/tela_de_entrar_na_turma.dart';
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
  await irPara(tester, '/turmas/entrar');
  expect(find.byType(TelaDeEntrarNaTurma), findsOneWidget);
}

FilledButton botaoEntrar(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Entrar na turma'),
);

void main() {
  testWidgets('o botão só habilita com oito caracteres válidos', (
    tester,
  ) async {
    await abrir(tester);
    expect(
      find.text('Peça o código de convite para alguém da turma.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'ABCD');
    await tester.pump();
    expect(botaoEntrar(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'abcd 2345');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'ABCD2345',
      reason: 'o formatador sobe para maiúsculas e tira o espaço',
    );
    expect(botaoEntrar(tester).onPressed, isNotNull);
  });

  testWidgets('código que a API não conhece vira erro no campo', (
    tester,
  ) async {
    final api = FakeApi(eu: euDeTeste());
    await abrir(tester, api: api);

    await tester.enterText(find.byType(TextField), 'ABCD2345');
    await tester.pump();
    await tester.tap(find.text('Entrar na turma'));
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('entrarNaTurma:ABCD2345'));
    expect(
      find.text('Código inválido. Confira com quem te convidou.'),
      findsOneWidget,
    );
    expect(find.byType(TelaDeEntrarNaTurma), findsOneWidget);
  });

  testWidgets('código certo entra, torna ativa e volta ao Feed', (
    tester,
  ) async {
    final api = FakeApi(
      eu: euDeTeste(),
      convites: {
        'WXYZ6789': turmaDeTeste(
          id: 'turma-2',
          nome: 'Cozinha & Prosa',
          codigoConvite: 'WXYZ6789',
          vezDe: pessoaDeTeste(),
          totalDeMembros: 3,
        ),
      },
    );
    final prefs = PreferenciasEmMemoria();
    await abrir(tester, api: api, preferencias: prefs);

    await tester.enterText(find.byType(TextField), 'wxyz6789');
    await tester.pump();
    await tester.tap(find.text('Entrar na turma'));
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('entrarNaTurma:WXYZ6789'));
    expect(prefs.valores['turma_ativa_id'], 'turma-2');
    expect(find.byType(TelaDoFeed), findsOneWidget);
  });

  testWidgets('colar a mensagem inteira do convite entra com o código dela', (
    tester,
  ) async {
    final turma = turmaDeTeste(
      id: 'turma-2',
      nome: 'Turma Teste',
      emoji: '🎲',
      codigoConvite: 'VKMTANJK',
      vezDe: pessoaDeTeste(),
      totalDeMembros: 2,
    );
    final api = FakeApi(eu: euDeTeste(), convites: {'VKMTANJK': turma});
    await abrir(tester, api: api);

    // o "Copiar" do compartilhamento, como o do WhatsApp, leva a mensagem e não só o código
    await tester.enterText(find.byType(TextField), textoDoConvite(turma));
    await tester.pump();
    await tester.tap(find.text('Entrar na turma'));
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('entrarNaTurma:VKMTANJK'));
    expect(find.byType(TelaDoFeed), findsOneWidget);
  });

  testWidgets('falha de rede avisa e a tela fica', (tester) async {
    final api = FakeApi(eu: euDeTeste())
      ..falhaAoEntrar = const ErroDeRede('caiu');
    await abrir(tester, api: api);

    await tester.enterText(find.byType(TextField), 'ABCD2345');
    await tester.pump();
    await tester.tap(find.text('Entrar na turma'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(find.byType(TelaDeEntrarNaTurma), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
