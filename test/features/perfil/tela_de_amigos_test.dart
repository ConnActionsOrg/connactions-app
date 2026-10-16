import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/app/app.dart';
import 'package:connactions_app/app/roteador.dart';
import 'package:connactions_app/design/widgets/avatar.dart';
import 'package:connactions_app/features/perfil/tela_de_amigos.dart';
import 'package:connactions_app/features/perfil/tela_de_conectar_amigo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());

/// A Bia e o Caio são contas da API; os pares vão do mais recente para o mais antigo.
FakeApi apiCom({List<(String, String)> conexoes = const []}) => FakeApi(
  eu: euDeTeste(),
  usuarios: [
    usuarioDeTeste(),
    usuarioDeTeste(
      id: 'pessoa-caio',
      handle: 'caio',
      nome: 'Caio Lima',
      codigoDeAmigo: 'CKXZ2345',
    ),
  ],
  conexoes: conexoes,
);

Future<void> abrir(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
  await irPara(tester, '/amigos');
  expect(find.byType(TelaDeAmigos), findsOneWidget);
}

/// A rota empilhada por último: o `push` não muda a `uri` da configuração, que segue a da aba.
String ondeEstou(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AppConnactions)))
        .read(roteadorProvider)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;

int leituras(FakeApi api) =>
    api.chamadas.where((c) => c == 'listarConexoes').length;

void main() {
  testWidgets('a lista na ordem do provider, com o nome e o @handle', (
    tester,
  ) async {
    await abrir(
      tester,
      apiCom(conexoes: [(eu.id, 'pessoa-bia'), ('pessoa-caio', eu.id)]),
    );

    expect(find.text('Amigos'), findsOneWidget);
    expect(find.text('@bia'), findsOneWidget);
    expect(find.text('@caio'), findsOneWidget);
    expect(find.byType(Avatar), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Bia Souza')).dy,
      lessThan(tester.getTopLeft(find.text('Caio Lima')).dy),
      reason: 'a conexão mais recente primeiro',
    );
  });

  testWidgets('tocar num amigo abre o perfil dele', (tester) async {
    await abrir(tester, apiCom(conexoes: [(eu.id, 'pessoa-caio')]));

    await tester.tap(find.text('Caio Lima'));
    await tester.pumpAndSettle();

    expect(ondeEstou(tester), '/pessoas/pessoa-caio');
  });

  testWidgets('sem amigos, o vazio com o botão de conectar', (tester) async {
    await abrir(tester, apiCom());

    expect(find.text('Você ainda não tem amigos no app'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Conectar amigo'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDeConectarAmigo), findsOneWidget);
  });

  testWidgets('a ação do topo abre o conectar', (tester) async {
    await abrir(tester, apiCom(conexoes: [(eu.id, 'pessoa-bia')]));

    await tester.tap(find.byTooltip('Conectar amigo'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDeConectarAmigo), findsOneWidget);
  });

  testWidgets('o erro oferece tentar de novo, que traz a lista', (
    tester,
  ) async {
    final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')])
      ..falhaAoListarConexoes = const ErroDeRede('caiu');
    await abrir(tester, api);
    expect(find.text('Algo não deu certo'), findsOneWidget);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );

    api.falhaAoListarConexoes = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Bia Souza'), findsOneWidget);
  });

  testWidgets(
    'o erro no perfil: tentar de novo relê a cadeia, não só a lista',
    (tester) async {
      final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')])
        ..falhaAoObter = const ErroDeRede('caiu');
      await abrir(tester, api);
      expect(find.text('Algo não deu certo'), findsOneWidget);

      api.falhaAoObter = null;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();

      expect(find.text('Bia Souza'), findsOneWidget);
    },
  );

  testWidgets('puxar para baixo relê a lista', (tester) async {
    final api = apiCom(conexoes: [(eu.id, 'pessoa-bia')]);
    await abrir(tester, api);
    expect(leituras(api), 1);
    // o Caio conectou do aparelho dele: sem realtime, só a próxima leitura o mostra
    api.conexoes.insert(0, ('pessoa-caio', eu.id));

    await tester.fling(
      find.descendant(
        of: find.byType(TelaDeAmigos),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(leituras(api), 2);
    expect(find.text('Caio Lima'), findsOneWidget);
  });
}
