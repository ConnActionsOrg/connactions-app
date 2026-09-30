import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/api/modelos/turma.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:connactions_app/features/turmas/tela_da_turma.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

FakeApi apiComTurma({Pessoa? vezDe, List<Membro>? membros, Atividade? aberta}) {
  final lista = membros ?? [membroDeTeste(eu, 1)];
  return FakeApi(
    eu: euDeTeste(),
    turmas: [
      turmaDeTeste(id: 'turma-1', vezDe: vezDe, totalDeMembros: lista.length),
    ],
    membrosPor: {'turma-1': lista},
    abertaPor: {'turma-1': aberta},
  );
}

Future<void> abrir(
  WidgetTester tester, {
  required FakeApi api,
  CompartilhadorFalso? compartilhador,
  String id = 'turma-1',
}) async {
  await tester.pumpWidget(appDeTeste(api: api, compartilhador: compartilhador));
  await tester.pumpAndSettle();
  await irPara(tester, '/turmas/$id');
  expect(find.byType(TelaDaTurma), findsOneWidget);
}

/// O botão de sair fica no fim do ListView, abaixo da dobra no viewport de teste.
Future<void> abrirDialogoDeSair(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Sair da turma'),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sair da turma'));
  await tester.pumpAndSettle();
  expect(find.text('Sair da turma?'), findsOneWidget);
}

void main() {
  testWidgets('mostra membros por ordem, quem é a vez e quem criou', (
    tester,
  ) async {
    await abrir(
      tester,
      api: apiComTurma(
        vezDe: bia,
        membros: [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
      ),
    );

    expect(find.text('🌿 Turma do Domingo'), findsOneWidget);
    expect(find.text('Membros (2)'), findsOneWidget);
    expect(find.text('@marina.d · criou a turma'), findsOneWidget);
    expect(find.text('@bia'), findsOneWidget);
    // a etiqueta "Vez" tem de estar na linha da Bia, não solta na tela
    final linhaDaBia = find
        .ancestor(of: find.text('Bia Souza'), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: linhaDaBia, matching: find.text('Vez')),
      findsOneWidget,
    );
    expect(find.text('Vez'), findsOneWidget);
    expect(find.text('ABCD2345'), findsOneWidget);
  });

  testWidgets('compartilhar entrega o texto com o código', (tester) async {
    final compartilhador = CompartilhadorFalso();
    await abrir(tester, api: apiComTurma(), compartilhador: compartilhador);

    await tester.tap(find.text('Compartilhar convite'));
    await tester.pumpAndSettle();

    expect(compartilhador.textos.single, contains('ABCD2345'));
    expect(compartilhador.textos.single, contains('Turma do Domingo'));
  });

  testWidgets('copiar põe só o código na área de transferência e avisa', (
    tester,
  ) async {
    await abrir(tester, api: apiComTurma());
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

    await tester.tap(find.byTooltip('Copiar código'));
    await tester.pumpAndSettle();

    expect(copiados, [
      {'text': 'ABCD2345'},
    ]);
    expect(find.text('Código copiado'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('gerar novo código passa pelo diálogo e atualiza a tela', (
    tester,
  ) async {
    final api = apiComTurma();
    await abrir(tester, api: api);

    await tester.tap(find.text('Gerar novo código'));
    await tester.pumpAndSettle();
    expect(find.text('Gerar novo código?'), findsOneWidget);

    await tester.tap(find.text('Gerar'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'regenerarConvite:turma-1');
    expect(find.text('ABCD2345'), findsNothing);
    expect(find.text(api.turmas.single.codigoConvite), findsOneWidget);
    expect(find.text('Novo código gerado'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('cancelar o diálogo não regenera', (tester) async {
    final api = apiComTurma();
    await abrir(tester, api: api);

    await tester.tap(find.text('Gerar novo código'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(api.chamadas.where((c) => c.startsWith('regenerar')), isEmpty);
    expect(find.text('ABCD2345'), findsOneWidget);
  });

  testWidgets('embaralhar reordena os membros e avisa', (tester) async {
    final api = apiComTurma(
      membros: [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
    );
    await abrir(tester, api: api);
    await tester.scrollUntilVisible(
      find.text('Embaralhar a ordem'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Embaralhar a ordem'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'embaralharOrdem:turma-1');
    final nomes = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .where((d) => d == 'Bia Souza' || d == 'Marina Duarte')
        .toList();
    expect(nomes, ['Bia Souza', 'Marina Duarte']);
    expect(find.text('Ordem embaralhada'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('com atividade aberta o embaralhar fica travado', (tester) async {
    await abrir(tester, api: apiComTurma(aberta: atividadeDeTeste()));
    await tester.scrollUntilVisible(
      find.text('Embaralhar a ordem'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    final botao = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Embaralhar a ordem'),
    );
    expect(botao.onPressed, isNull);
    expect(
      find.text('Com uma atividade aberta, a ordem fica travada.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'sem conseguir ler a atividade aberta, o embaralhar fica travado',
    (tester) async {
      final api = apiComTurma()..falhaAoObterAberta = const ErroDeRede('caiu');
      await abrir(tester, api: api);
      await tester.scrollUntilVisible(
        find.text('Embaralhar a ordem'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      final botao = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Embaralhar a ordem'),
      );
      expect(botao.onPressed, isNull);
    },
  );

  testWidgets(
    'ordem travada por outro aparelho avisa e passa a travar o botão',
    (tester) async {
      final api = apiComTurma();
      await abrir(tester, api: api);
      await tester.scrollUntilVisible(
        find.text('Embaralhar a ordem'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      int leiturasDaAberta() =>
          api.chamadas.where((c) => c == 'obterAtividadeAberta:turma-1').length;
      final leiturasAntes = leiturasDaAberta();
      // alguém lançou uma atividade depois que esta tela leu a aberta
      api.abertaPor['turma-1'] = atividadeDeTeste();

      await tester.tap(find.text('Embaralhar a ordem'));
      await tester.pumpAndSettle();

      expect(
        find.text('A ordem não pode ser embaralhada com uma atividade aberta.'),
        findsOneWidget,
      );
      expect(leiturasDaAberta(), leiturasAntes + 1);
      final botao = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Embaralhar a ordem'),
      );
      expect(botao.onPressed, isNull);
      expect(
        find.text('Com uma atividade aberta, a ordem fica travada.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('sair como último membro avisa que apaga a turma', (
    tester,
  ) async {
    await abrir(
      tester,
      api: apiComTurma(vezDe: eu, membros: [membroDeTeste(eu, 1)]),
    );
    await abrirDialogoDeSair(tester);
    expect(
      find.text('Você é a última pessoa: sair apaga a turma.'),
      findsOneWidget,
    );
  });

  testWidgets('sair sendo a vez avisa que ela passa adiante', (tester) async {
    await abrir(
      tester,
      api: apiComTurma(
        vezDe: eu,
        membros: [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
      ),
    );
    await abrirDialogoDeSair(tester);
    expect(
      find.text('A vez passa para a próxima pessoa da ordem.'),
      findsOneWidget,
    );
  });

  testWidgets('sair sem ser a vez avisa que dá para voltar; confirmar sai', (
    tester,
  ) async {
    final api = apiComTurma(
      vezDe: bia,
      membros: [membroDeTeste(bia, 1), membroDeTeste(eu, 2)],
    );
    await abrir(tester, api: api);
    await abrirDialogoDeSair(tester);
    expect(find.text('Você pode voltar com um novo convite.'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'sairDaTurma:turma-1');
    expect(find.byType(TelaDoFeed), findsOneWidget);
    expect(find.text('Você saiu de Turma do Domingo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('turma que não está na lista avisa e oferece voltar', (
    tester,
  ) async {
    await abrir(tester, api: apiComTurma(), id: 'turma-99');
    expect(find.text('Você não está mais nesta turma.'), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDoFeed), findsOneWidget);
  });

  testWidgets('detalhe negado (403) mostra que saí da turma', (tester) async {
    final api = apiComTurma()
      ..falhaAoObterTurma = const ErroDaApi(
        status: 403,
        codigo: 'sem_acesso',
        mensagem: 'Você não faz parte desta turma.',
      );
    await abrir(tester, api: api);

    expect(find.text('Você não está mais nesta turma.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('erro ao carregar membros oferece tentar de novo', (
    tester,
  ) async {
    final api = apiComTurma()..falhaAoObterTurma = const ErroDeRede('caiu');
    await abrir(tester, api: api);
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(
      find.text('ABCD2345'),
      findsOneWidget,
      reason: 'o convite vem da lista, não do detalhe',
    );

    api.falhaAoObterTurma = null;
    // como o botão de sair, "Tentar de novo" cai abaixo da dobra no viewport de teste.
    await tester.scrollUntilVisible(
      find.text('Tentar de novo'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('@marina.d · criou a turma'), findsOneWidget);
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrir(tester, api: apiComTurma());
    final scaffold = find.descendant(
      of: find.byType(TelaDaTurma),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });
}
