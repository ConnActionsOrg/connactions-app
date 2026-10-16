import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/app/app.dart';
import 'package:connactions_app/design/widgets/avatar.dart';
import 'package:connactions_app/design/widgets/estado_vazio.dart';
import 'package:connactions_app/features/perfil/cartao_de_atividade_feita.dart';
import 'package:connactions_app/features/perfil/conexoes.dart';
import 'package:connactions_app/features/perfil/linha_de_contadores.dart';
import 'package:connactions_app/features/perfil/perfil_da_pessoa.dart';
import 'package:connactions_app/features/perfil/tela_da_pessoa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());
final agora = DateTime.utc(2026, 10, 20, 12);

/// A Bia é minha conexão, está em 3 turmas e tem [feitas] atividades feitas, todas públicas.
FakeApi apiCom({
  bool biaVisivel = true,
  int feitas = 2,
  List<(String, String)>? conexoes,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  usuarios: [
    usuarioDeTeste(
      bio: 'Trilha aos domingos',
      turmas: 3,
      atividadesVisiveis: biaVisivel,
    ),
  ],
  conexoes: conexoes ?? [(eu.id, 'pessoa-bia')],
  feitasPor: {
    'pessoa-bia': [
      for (var i = 1; i <= feitas; i++)
        feitaDeTeste(id: 'f$i', titulo: 'Atividade $i'),
    ],
  },
);

Future<ProviderContainer> abrir(
  WidgetTester tester,
  FakeApi api, {
  String id = 'pessoa-bia',
}) async {
  await tester.pumpWidget(appDeTeste(api: api, agora: agora));
  await tester.pumpAndSettle();
  await irPara(tester, '/pessoas/$id');
  expect(find.byType(TelaDaPessoa), findsOneWidget);
  return ProviderScope.containerOf(tester.element(find.byType(AppConnactions)));
}

List<String> amigos(ProviderContainer c) => [
  for (final p in c.read(conexoesProvider).value ?? const <Pessoa>[]) p.id,
];

int desconectares(FakeApi api) =>
    api.chamadas.where((c) => c.startsWith('desconectar:')).length;

/// Do menu ⋮ até o diálogo de confirmação aberto.
Future<void> pedirParaDesconectar(WidgetTester tester) async {
  await tester.tap(find.byIcon(Symbols.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Desconectar'));
  await tester.pumpAndSettle();
}

Finder lista() => find
    .descendant(
      of: find.byType(TelaDaPessoa),
      matching: find.byType(Scrollable),
    )
    .first;

void telaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// O SnackBar arma um Timer de 4 s; deixá-lo pendente reprova o teste no teardown.
Future<void> esperarOAvisoSair(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('o cabeçalho e os três contadores', (tester) async {
    telaAlta(tester);
    await abrir(tester, apiCom());

    expect(find.byType(Avatar), findsOneWidget);
    expect(find.text('Bia Souza'), findsOneWidget);
    expect(find.text('@bia'), findsOneWidget);
    expect(find.text('Trilha aos domingos'), findsOneWidget);
    final linha = find.byType(LinhaDeContadores);
    for (final texto in ['3', 'Turmas', '2', 'Atividades', '1', 'Conexão']) {
      expect(
        find.descendant(of: linha, matching: find.text(texto)),
        findsOneWidget,
        reason: texto,
      );
    }
    expect(find.byType(CartaoDeAtividadeFeita), findsNWidgets(2));
  });

  testWidgets(
    'deixou as atividades só para si: sem o contador, com o vazio dela, e a lista nem é pedida',
    (tester) async {
      final api = apiCom(biaVisivel: false);
      await abrir(tester, api);

      expect(find.text('Bia deixou as atividades só para si.'), findsOneWidget);
      expect(find.text('Atividades'), findsNothing);
      expect(find.text('Turmas'), findsOneWidget);
      expect(
        api.chamadas.where((c) => c.startsWith('listarAtividadesFeitas')),
        isEmpty,
      );
    },
  );

  testWidgets('a lista vazia diz que não há o que eu possa ver', (
    tester,
  ) async {
    await abrir(tester, apiCom(feitas: 0));

    expect(
      find.text('Bia ainda não tem atividades que você possa ver.'),
      findsOneWidget,
    );
  });

  testWidgets('o carregar mais traz a página seguinte e some no fim', (
    tester,
  ) async {
    final api = apiCom(feitas: 22);
    await abrir(tester, api);

    await tester.scrollUntilVisible(
      find.text('Carregar mais'),
      300,
      scrollable: lista(),
    );
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'listarAtividadesFeitas:pessoa-bia:20');
    await tester.scrollUntilVisible(
      find.text('Atividade 22'),
      300,
      scrollable: lista(),
    );
    expect(find.text('Carregar mais', skipOffstage: false), findsNothing);
  });

  testWidgets(
    'o Carregar mais que recebe 403 avisa, e a lista fica com o que já estava',
    (tester) async {
      final api = apiCom(feitas: 22);
      final c = await abrir(tester, api);
      await tester.scrollUntilVisible(
        find.text('Carregar mais'),
        300,
        scrollable: lista(),
      );
      // a Bia desligou a visibilidade enquanto eu lia a primeira página
      api.usuarios['pessoa-bia']!.atividadesVisiveis = false;

      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(find.text('Essas atividades não estão visíveis.'), findsOneWidget);
      expect(find.text('Algo não deu certo'), findsNothing);
      expect(find.text('Carregar mais'), findsOneWidget);
      expect(find.byType(CartaoDeAtividadeFeita), findsWidgets);
      expect(
        c.read(atividadesFeitasProvider('pessoa-bia')).value!.itens,
        hasLength(20),
      );
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets('o 403 do perfil: "Vocês não estão conectados." e o Voltar', (
    tester,
  ) async {
    await abrir(tester, apiCom(conexoes: const []));

    expect(
      find.widgetWithText(EstadoVazio, 'Vocês não estão conectados.'),
      findsOneWidget,
    );
    // tentar de novo não adianta: só o outro pode dar o código de novo
    expect(find.text('Tentar de novo'), findsNothing);
    expect(find.byIcon(Symbols.more_vert), findsNothing);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDaPessoa), findsNothing);
  });

  testWidgets('outro erro: tentar de novo traz o perfil', (tester) async {
    final api = apiCom()..falhaAoObterPerfil = const ErroDeRede('caiu');
    await abrir(tester, api);
    expect(find.text('Algo não deu certo'), findsOneWidget);

    api.falhaAoObterPerfil = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Bia Souza'), findsOneWidget);
  });

  testWidgets(
    'desconectar: o diálogo exato, a volta, o aviso e a Bia fora da lista',
    (tester) async {
      final api = apiCom();
      final c = await abrir(tester, api);
      await c.read(conexoesProvider.future);

      await pedirParaDesconectar(tester);
      expect(find.text('Desconectar de Bia?'), findsOneWidget);
      expect(
        find.text(
          'Vocês deixam de ver o perfil um do outro. Para voltar, um dos dois precisa do código do outro.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Desconectar'));
      await tester.pumpAndSettle();

      expect(api.chamadas, contains('desconectar:pessoa-bia'));
      expect(find.byType(TelaDaPessoa), findsNothing);
      expect(
        find.text('Você e Bia não estão mais conectados.'),
        findsOneWidget,
      );
      expect(amigos(c), isEmpty);
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets('cancelar o diálogo não desconecta', (tester) async {
    final api = apiCom();
    await abrir(tester, api);

    await pedirParaDesconectar(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(desconectares(api), 0);
    expect(find.byType(TelaDaPessoa), findsOneWidget);
  });

  testWidgets('o toque duplo no desconectar faz uma chamada só', (
    tester,
  ) async {
    final api = apiCom();
    await abrir(tester, api);
    final segurar = api.segurarDesconectar = Completer<void>();

    await pedirParaDesconectar(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Desconectar'));
    await tester.pumpAndSettle();
    // com a chamada no ar, o menu não abre de novo
    await tester.tap(find.byIcon(Symbols.more_vert), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Desconectar'), findsNothing);

    segurar.complete();
    await tester.pumpAndSettle();
    expect(desconectares(api), 1);
    await esperarOAvisoSair(tester);
  });

  testWidgets(
    'fechar a tela com o desconectar no ar: a Bia sai da lista e o aviso sai mesmo assim',
    (tester) async {
      final api = apiCom();
      final c = await abrir(tester, api);
      await c.read(conexoesProvider.future);
      final segurar = api.segurarDesconectar = Completer<void>();

      await pedirParaDesconectar(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Desconectar'));
      await tester.pumpAndSettle();
      // o pageBack procura o tooltip "Back", e o app é em português
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(TelaDaPessoa), findsNothing);
      segurar.complete();
      await tester.pumpAndSettle();

      expect(amigos(c), isEmpty);
      expect(
        find.text('Você e Bia não estão mais conectados.'),
        findsOneWidget,
      );
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets('no meu próprio id, sem o menu', (tester) async {
    await abrir(tester, apiCom(), id: eu.id);

    expect(find.text('Marina Duarte'), findsOneWidget);
    expect(find.byIcon(Symbols.more_vert), findsNothing);
  });

  testWidgets(
    'desconectada do outro lado com a tela aberta: puxar para atualizar mostra que não estão conectados',
    (tester) async {
      final api = apiCom();
      await abrir(tester, api);
      api.conexoes.clear();

      await tester.fling(lista(), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(EstadoVazio, 'Vocês não estão conectados.'),
        findsOneWidget,
      );
      expect(find.text('Voltar'), findsOneWidget);
      await esperarOAvisoSair(tester);
    },
  );

  testWidgets(
    'a visibilidade desligada no meio: puxar para atualizar mostra o só para si, sem o aviso do 403',
    (tester) async {
      // na tela padrão, o arrasto de 300 px passa com folga do ponto que arma o indicador
      final api = apiCom();
      await abrir(tester, api);
      expect(find.byType(CartaoDeAtividadeFeita), findsWidgets);
      api.usuarios['pessoa-bia']!.atividadesVisiveis = false;

      await tester.fling(lista(), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Bia deixou as atividades só para si.'), findsOneWidget);
      expect(find.text('Atividades'), findsNothing);
      expect(find.byType(CartaoDeAtividadeFeita), findsNothing);
      expect(find.text('Essas atividades não estão visíveis.'), findsNothing);
    },
  );
}
