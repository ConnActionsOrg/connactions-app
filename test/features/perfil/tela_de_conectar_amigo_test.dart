import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/api/modelos/turma.dart';
import 'package:connactions_app/app/app.dart';
import 'package:connactions_app/features/perfil/codigo_de_amigo.dart';
import 'package:connactions_app/features/perfil/conexoes.dart';
import 'package:connactions_app/features/perfil/tela_de_conectar_amigo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());

/// A Bia (código BEAZ2345) é uma conta da API; só o que o teste pedir a conecta a mim.
FakeApi apiCom({
  List<(String, String)> conexoes = const [],
  List<Turma> turmas = const [],
}) => FakeApi(
  eu: euDeTeste(),
  turmas: turmas,
  usuarios: [usuarioDeTeste()],
  conexoes: conexoes,
);

Future<ProviderContainer> abrir(
  WidgetTester tester,
  FakeApi api, {
  CompartilhadorFalso? compartilhador,
}) async {
  await tester.pumpWidget(appDeTeste(api: api, compartilhador: compartilhador));
  await tester.pumpAndSettle();
  await irPara(tester, '/amigos/conectar');
  expect(find.byType(TelaDeConectarAmigo), findsOneWidget);
  return ProviderScope.containerOf(tester.element(find.byType(AppConnactions)));
}

TextField campo(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

FilledButton botaoConectar(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Conectar'));

List<String> amigos(ProviderContainer c) => [
  for (final p in c.read(conexoesProvider).value ?? const <Pessoa>[]) p.id,
];

int conectares(FakeApi api) =>
    api.chamadas.where((c) => c.startsWith('conectar:')).length;

Future<void> conectar(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Conectar'));
  await tester.pumpAndSettle();
}

/// O SnackBar arma um Timer de 4 s; deixá-lo pendente reprova o teste no teardown.
Future<void> esperarOAvisoSair(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('o botão só habilita com oito caracteres válidos', (
    tester,
  ) async {
    await abrir(tester, apiCom());

    expect(campo(tester).decoration!.labelText, 'Código do amigo');
    await tester.enterText(find.byType(TextField), 'BEAZ');
    await tester.pump();
    expect(botaoConectar(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'beaz 2345');
    await tester.pump();
    expect(campo(tester).controller!.text, 'BEAZ2345');
    expect(botaoConectar(tester).onPressed, isNotNull);
  });

  testWidgets(
    'colar a mensagem inteira do amigo conecta, volta e avisa com o primeiro nome',
    (tester) async {
      final api = apiCom();
      final c = await abrir(tester, api);

      // o "Copiar" do WhatsApp leva a mensagem toda, e não só o código
      await tester.enterText(
        find.byType(TextField),
        textoDoCodigoDeAmigo('BEAZ2345'),
      );
      await tester.pump();
      expect(campo(tester).controller!.text, 'BEAZ2345');
      await tester.tap(find.widgetWithText(FilledButton, 'Conectar'));
      await tester.pumpAndSettle();

      expect(api.chamadas, contains('conectar:BEAZ2345'));
      expect(find.byType(TelaDeConectarAmigo), findsNothing);
      expect(find.text('Agora você e Bia estão conectados.'), findsOneWidget);
      expect(amigos(c), ['pessoa-bia']);
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets('com quem já era amigo, volta e avisa que já estavam', (
    tester,
  ) async {
    final c = await abrir(tester, apiCom(conexoes: [(eu.id, 'pessoa-bia')]));

    await conectar(tester, 'BEAZ2345');

    expect(find.byType(TelaDeConectarAmigo), findsNothing);
    expect(find.text('Vocês já estavam conectados.'), findsOneWidget);
    expect(amigos(c), ['pessoa-bia']);
    await esperarOAvisoSair(tester);
  });

  testWidgets('o código de ninguém aparece abaixo do campo, e o texto fica', (
    tester,
  ) async {
    await abrir(tester, apiCom());

    await conectar(tester, 'ZZZZ9999');

    expect(find.byType(TelaDeConectarAmigo), findsOneWidget);
    expect(
      campo(tester).decoration!.errorText,
      'Não achei ninguém com esse código de amigo.',
    );
    expect(
      find.text('Não achei ninguém com esse código de amigo.'),
      findsOneWidget,
      reason: 'no campo, e não num aviso',
    );
    expect(campo(tester).controller!.text, 'ZZZZ9999');
  });

  testWidgets(
    'o convite de uma turma no campo dá o erro abaixo dele e não muda a lista de amigos',
    (tester) async {
      // o convite tem o mesmo alfabeto e o mesmo tamanho do código de amigo
      final api = apiCom(turmas: [turmaDeTeste(codigoConvite: 'ABCD2345')]);
      final c = await abrir(tester, api);

      await conectar(tester, 'ABCD2345');

      expect(api.chamadas, contains('conectar:ABCD2345'));
      expect(
        campo(tester).decoration!.errorText,
        'Não achei ninguém com esse código de amigo.',
      );
      expect(campo(tester).controller!.text, 'ABCD2345');
      expect(api.conexoes, isEmpty);
      expect(amigos(c), isEmpty);
    },
  );

  testWidgets('o meu próprio código dá a mensagem própria abaixo do campo', (
    tester,
  ) async {
    await abrir(tester, apiCom());

    await conectar(tester, euDeTeste().codigoDeAmigo);

    expect(
      campo(tester).decoration!.errorText,
      'Esse é o seu código. Peça o do seu amigo.',
    );
  });

  testWidgets('editar o campo apaga o erro', (tester) async {
    await abrir(tester, apiCom());
    await conectar(tester, 'ZZZZ9999');
    expect(campo(tester).decoration!.errorText, isNotNull);

    await tester.enterText(find.byType(TextField), 'ZZZZ999');
    await tester.pump();

    expect(campo(tester).decoration!.errorText, isNull);
  });

  testWidgets('a falha de rede vira aviso e a tela fica', (tester) async {
    final api = apiCom()..falhaAoConectar = const ErroDeRede('caiu');
    await abrir(tester, api);

    await conectar(tester, 'BEAZ2345');

    expect(find.byType(TelaDeConectarAmigo), findsOneWidget);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(campo(tester).decoration!.errorText, isNull);
    await esperarOAvisoSair(tester);
  });

  testWidgets('o toque duplo em Conectar faz uma chamada só', (tester) async {
    final api = apiCom();
    await abrir(tester, api);
    final segurar = api.segurarConectar = Completer<void>();
    await tester.enterText(find.byType(TextField), 'BEAZ2345');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Conectar'));
    await tester.pump();
    // com a chamada no ar o botão mostra o progresso no lugar do texto
    await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
    await tester.pump();

    expect(conectares(api), 1);
    segurar.complete();
    await tester.pumpAndSettle();
    expect(conectares(api), 1);
    expect(find.text('Agora você e Bia estão conectados.'), findsOneWidget);
    await esperarOAvisoSair(tester);
  });

  testWidgets(
    'fechar a tela com o conectar no ar: a Bia entra na lista e o aviso sai mesmo assim',
    (tester) async {
      final api = apiCom();
      final c = await abrir(tester, api);
      final segurar = api.segurarConectar = Completer<void>();
      await tester.enterText(find.byType(TextField), 'BEAZ2345');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Conectar'));
      await tester.pump();

      // o pageBack procura o tooltip "Back", e o app é em português
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(TelaDeConectarAmigo), findsNothing);
      segurar.complete();
      await tester.pumpAndSettle();

      expect(amigos(c), ['pessoa-bia']);
      expect(find.text('Agora você e Bia estão conectados.'), findsOneWidget);
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets(
    'o meu código: grande, o Copiar avisa e o Compartilhar leva a mensagem',
    (tester) async {
      final compartilhador = CompartilhadorFalso();
      await abrir(tester, apiCom(), compartilhador: compartilhador);
      final copiados = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          if (chamada.method == 'Clipboard.setData') {
            copiados.add(chamada.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      expect(find.text('Seu código'), findsOneWidget);
      expect(find.text('ABCDEFGH'), findsOneWidget);

      await tester.tap(find.text('Copiar'));
      await tester.pumpAndSettle();
      expect(copiados, [
        {'text': 'ABCDEFGH'},
      ]);
      expect(find.text('Código copiado'), findsOneWidget);

      await tester.tap(find.text('Compartilhar'));
      await tester.pumpAndSettle();
      expect(compartilhador.textos, [textoDoCodigoDeAmigo('ABCDEFGH')]);
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets(
    'gerar um código novo pede a confirmação e troca o código na tela',
    (tester) async {
      final api = apiCom();
      await abrir(tester, api);

      await tester.tap(find.text('Gerar código novo'));
      await tester.pumpAndSettle();
      expect(find.text('Gerar um código novo?'), findsOneWidget);
      expect(
        find.text(
          'O código atual para de funcionar. Quem já é seu amigo continua conectado.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Gerar'));
      await tester.pumpAndSettle();

      expect(api.chamadas, contains('regenerarCodigoDeAmigo'));
      expect(find.text('ABCDEFGH'), findsNothing);
      expect(find.text('MUDADA22'), findsOneWidget);
      expect(find.text('Novo código gerado'), findsOneWidget);
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets('cancelar o diálogo não gera código', (tester) async {
    final api = apiCom();
    await abrir(tester, api);

    await tester.tap(find.text('Gerar código novo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(api.chamadas, isNot(contains('regenerarCodigoDeAmigo')));
    expect(find.text('ABCDEFGH'), findsOneWidget);
  });

  testWidgets('com o código novo no ar, gerar de novo fica travado', (
    tester,
  ) async {
    final api = apiCom();
    await abrir(tester, api);
    final segurar = api.segurarRegenerarCodigoDeAmigo = Completer<void>();

    await tester.tap(find.text('Gerar código novo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar'));
    // o diálogo termina de sair; a chamada continua presa
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(TextButton, 'Gerar código novo'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Gerar um código novo?'), findsNothing);
    segurar.complete();
    await tester.pumpAndSettle();
    expect(
      api.chamadas.where((c) => c == 'regenerarCodigoDeAmigo'),
      hasLength(1),
    );
    await esperarOAvisoSair(tester);
  });
}
