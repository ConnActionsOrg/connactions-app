import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/features/atividades/tela_de_propor.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:connactions_app/features/ideias/tela_do_backlog.dart';
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
  regras: const ['Levar água'],
  formato: FormatoDeAtividade.individual,
  autor: bia,
);
final pizza = ideiaDeTeste(id: 'i1', titulo: 'Pizza');

FakeApi apiCom({
  List<Ideia> ideias = const [],
  List<AtividadeDaComunidade> comunidade = const [],
  Object? falhaAoLancar,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  ideiasPor: {'turma-1': ideias},
  comunidade: comunidade,
  falhaAoLancar: falhaAoLancar,
);

Future<void> abrirPeloFeed(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api, agora: agora));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Propor atividade'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDePropor), findsOneWidget);
}

/// Só o que está dentro do Propor: o Feed por baixo também tem "Comunidade" na barra de abas.
Finder naTela(String texto) =>
    find.descendant(of: find.byType(TelaDePropor), matching: find.text(texto));

Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

String textoDe(WidgetTester tester, String rotulo) =>
    tester.widget<TextField>(campo(rotulo)).controller!.text;

/// Rola a lista da tela. Cada `TextField` traz um `Scrollable` próprio, que vem depois dela na
/// árvore: `.last` pegaria o de um campo.
Finder listaDaTela() => find
    .descendant(
      of: find.byType(TelaDePropor),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(alvo, 200, scrollable: listaDaTela());
  await tester.pumpAndSettle();
}

/// Com o formulário rolado até o botão, as abinhas ficam fora da tela: sobe até elas antes de tocar.
Future<void> irParaAba(WidgetTester tester, String aba) async {
  await tester.scrollUntilVisible(naTela(aba), -300, scrollable: listaDaTela());
  await tester.ensureVisible(naTela(aba));
  await tester.pumpAndSettle();
  await tester.tap(naTela(aba));
  await tester.pumpAndSettle();
}

Future<void> lancar(WidgetTester tester) async {
  await rolarAte(tester, find.text('Lançar atividade'));
  await tester.tap(find.text('Lançar atividade'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('três abinhas, e os campos não se perdem ao alternar', (
    tester,
  ) async {
    await abrirPeloFeed(tester, apiCom());
    expect(naTela('Do zero'), findsOneWidget);
    expect(naTela('Backlog'), findsOneWidget);
    expect(naTela('Comunidade'), findsOneWidget);

    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();
    await irParaAba(tester, 'Backlog');
    expect(campo('Nome da atividade'), findsNothing);
    await irParaAba(tester, 'Comunidade');
    await irParaAba(tester, 'Do zero');

    expect(textoDe(tester, 'Nome da atividade'), 'Piquenique');
  });

  testWidgets('Backlog: as ideias com "Propor esta" e sem "Apagar"', (
    tester,
  ) async {
    await abrirPeloFeed(tester, apiCom(ideias: [trilha, pizza]));

    await irParaAba(tester, 'Backlog');

    expect(find.text('Trilha'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Propor esta'), findsNWidgets(2));
    expect(find.text('Apagar'), findsNothing);
    expect(find.text('Sugerido por Bia'), findsOneWidget);
    expect(find.text('Sua ideia'), findsOneWidget);
  });

  testWidgets('Backlog vazio', (tester) async {
    await abrirPeloFeed(tester, apiCom());

    await irParaAba(tester, 'Backlog');

    expect(find.text('O backlog da turma está vazio'), findsOneWidget);
    expect(
      find.text('As ideias que a turma guardar aparecem aqui.'),
      findsOneWidget,
    );
  });

  testWidgets('escolher uma ideia preenche e mostra o chip; o ✕ o desfaz', (
    tester,
  ) async {
    await abrirPeloFeed(tester, apiCom(ideias: [trilha, pizza]));
    await irParaAba(tester, 'Backlog');

    await tester.tap(find.text('Propor esta').first);
    await tester.pumpAndSettle();

    expect(find.text('Propor esta'), findsNothing);
    expect(textoDe(tester, 'Nome da atividade'), 'Trilha');
    expect(textoDe(tester, 'Como vai funcionar?'), 'Subir o morro.');
    expect(textoDe(tester, 'Regras (opcional), uma por linha'), 'Levar água');
    expect(find.text('Ideia de Bia'), findsOneWidget);

    await tester.tap(find.byTooltip('Desfazer a origem'));
    await tester.pumpAndSettle();

    expect(find.text('Ideia de Bia'), findsNothing);
    expect(textoDe(tester, 'Nome da atividade'), 'Trilha');
  });

  testWidgets('escolher outra origem substitui a anterior', (tester) async {
    await abrirPeloFeed(tester, apiCom(ideias: [trilha, pizza]));
    await irParaAba(tester, 'Backlog');
    await tester.tap(find.text('Propor esta').first);
    await tester.pumpAndSettle();
    expect(find.text('Ideia de Bia'), findsOneWidget);

    await irParaAba(tester, 'Backlog');
    // o botão da 2ª ideia fica abaixo da dobra do viewport de teste
    await tester.ensureVisible(find.text('Propor esta').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Propor esta').last);
    await tester.pumpAndSettle();

    expect(find.text('Ideia de Bia'), findsNothing);
    expect(find.text('Sua ideia'), findsOneWidget);
    expect(textoDe(tester, 'Nome da atividade'), 'Pizza');
  });

  testWidgets('lançar com a ideia manda só origem_ideia_id', (tester) async {
    final api = apiCom(ideias: [trilha, pizza]);
    await abrirPeloFeed(tester, api);
    await irParaAba(tester, 'Backlog');
    await tester.tap(find.text('Propor esta').first);
    await tester.pumpAndSettle();

    await lancar(tester);

    expect(api.ultimaProposta?.origemIdeiaId, 'i2');
    expect(api.ultimaProposta?.origemAtividadeId, isNull);
    expect(api.ultimaProposta?.formato, FormatoDeAtividade.individual);
    expect(find.byType(TelaDePropor), findsNothing);
    expect(find.byType(TelaDoFeed), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('lançar do zero não manda origem nenhuma', (tester) async {
    final api = apiCom();
    await abrirPeloFeed(tester, api);
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();

    await lancar(tester);

    expect(api.ultimaProposta?.origemIdeiaId, isNull);
    expect(api.ultimaProposta?.origemAtividadeId, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Comunidade: lista compacta e o chip da turma', (tester) async {
    final api = apiCom(
      comunidade: [atividadeDaComunidadeDeTeste(inspiradas: 2)],
    );
    await abrirPeloFeed(tester, api);

    await irParaAba(tester, 'Comunidade');

    expect(find.text('Turma Prova'), findsOneWidget);
    expect(find.text('Noite de jogos'), findsOneWidget);
    expect(find.text('Cada um leva um jogo.'), findsOneWidget);
    expect(find.text('2 turmas se inspiraram'), findsOneWidget);
    expect(find.text('Carregar mais'), findsNothing);

    await tester.tap(find.text('Usar esta ideia'));
    await tester.pumpAndSettle();

    expect(textoDe(tester, 'Nome da atividade'), 'Noite de jogos');
    expect(
      textoDe(tester, 'Regras (opcional), uma por linha'),
      'Um jogo por pessoa',
    );
    expect(find.text('Da Comunidade · 🍕 Turma Prova'), findsOneWidget);

    await lancar(tester);

    expect(api.ultimaProposta?.origemAtividadeId, 'com-1');
    expect(api.ultimaProposta?.origemIdeiaId, isNull);
    expect(api.ultimaProposta?.formato, FormatoDeAtividade.grupo);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Comunidade vazia', (tester) async {
    await abrirPeloFeed(tester, apiCom());

    await irParaAba(tester, 'Comunidade');

    expect(find.text('A comunidade ainda está quieta'), findsOneWidget);
  });

  testWidgets('Comunidade: "Carregar mais" traz a página seguinte', (
    tester,
  ) async {
    final api = apiCom(
      comunidade: [
        for (var i = 1; i <= 22; i++)
          atividadeDaComunidadeDeTeste(id: 'com-$i', titulo: 'Atividade $i'),
      ],
    );
    await abrirPeloFeed(tester, api);
    await irParaAba(tester, 'Comunidade');
    await rolarAte(tester, find.text('Carregar mais'));

    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    await rolarAte(tester, find.text('Atividade 22'));
    expect(find.text('Atividade 22'), findsOneWidget);
    expect(find.text('Carregar mais', skipOffstage: false), findsNothing);
  });

  testWidgets('ideia_indisponivel: a tela fica, o texto fica e o vínculo cai', (
    tester,
  ) async {
    final api = apiCom(
      ideias: [trilha],
      falhaAoLancar: const ErroDaApi(
        status: 409,
        codigo: 'ideia_indisponivel',
        mensagem: 'Essa ideia já foi usada ou apagada.',
      ),
    );
    await abrirPeloFeed(tester, api);
    await irParaAba(tester, 'Backlog');
    await tester.tap(find.text('Propor esta'));
    await tester.pumpAndSettle();
    expect(find.text('Ideia de Bia'), findsOneWidget);

    await lancar(tester);

    expect(find.byType(TelaDePropor), findsOneWidget);
    expect(find.text('Essa ideia já foi usada ou apagada.'), findsOneWidget);
    expect(find.text('Ideia de Bia'), findsNothing);
    expect(textoDe(tester, 'Nome da atividade'), 'Trilha');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // o backlog é relido na próxima visita: a ideia que alguém usou já não está lá
    api
      ..falhaAoLancar = null
      ..ideiasPor['turma-1']!.clear();
    await irParaAba(tester, 'Backlog');
    expect(find.text('O backlog da turma está vazio'), findsOneWidget);

    // sem o vínculo, a pessoa ainda pode lançar o texto como ideia dela
    await irParaAba(tester, 'Do zero');
    await lancar(tester);
    expect(api.ultimaProposta?.origemIdeiaId, isNull);
    expect(find.byType(TelaDePropor), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('outro 409 continua fechando a tela e avisando', (tester) async {
    final api = apiCom(
      falhaAoLancar: const ErroDaApi(
        status: 409,
        codigo: 'atividade_ja_aberta',
        mensagem: 'A turma já tem uma atividade aberta.',
      ),
    );
    await abrirPeloFeed(tester, api);
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();

    await lancar(tester);

    expect(find.byType(TelaDePropor), findsNothing);
    expect(find.text('A turma já tem uma atividade aberta.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('422 da origem da Comunidade: só o aviso, e o ✕ resolve', (
    tester,
  ) async {
    final api = apiCom(
      comunidade: [atividadeDaComunidadeDeTeste()],
      falhaAoLancar: const ErroDaApi(
        status: 422,
        codigo: 'dados_invalidos',
        mensagem: 'A atividade de origem não está na Comunidade.',
      ),
    );
    await abrirPeloFeed(tester, api);
    await irParaAba(tester, 'Comunidade');
    await tester.tap(find.text('Usar esta ideia'));
    await tester.pumpAndSettle();

    await lancar(tester);

    expect(find.byType(TelaDePropor), findsOneWidget);
    expect(
      find.text('A atividade de origem não está na Comunidade.'),
      findsOneWidget,
    );
    expect(find.text('Da Comunidade · 🍕 Turma Prova'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    api.falhaAoLancar = null;
    await rolarAte(tester, find.byTooltip('Desfazer a origem'));
    await tester.tap(find.byTooltip('Desfazer a origem'));
    await tester.pumpAndSettle();
    await lancar(tester);

    expect(api.ultimaProposta?.origemAtividadeId, isNull);
    expect(find.byType(TelaDePropor), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('aberto de fora com uma ideia no extra, já vem preenchido', (
    tester,
  ) async {
    final api = apiCom(ideias: [trilha]);
    await tester.pumpWidget(appDeTeste(api: api, agora: agora));
    await tester.pumpAndSettle();

    await irParaComExtra(tester, '/turmas/turma-1/propor', trilha);

    expect(find.byType(TelaDePropor), findsOneWidget);
    expect(textoDe(tester, 'Nome da atividade'), 'Trilha');
    expect(find.text('Ideia de Bia'), findsOneWidget);
  });

  testWidgets('aberto de fora com uma atividade da Comunidade no extra', (
    tester,
  ) async {
    await tester.pumpWidget(appDeTeste(api: apiCom(), agora: agora));
    await tester.pumpAndSettle();

    await irParaComExtra(
      tester,
      '/turmas/turma-1/propor',
      atividadeDaComunidadeDeTeste(titulo: 'Campeonato de boliche'),
    );

    expect(textoDe(tester, 'Nome da atividade'), 'Campeonato de boliche');
    expect(find.text('Da Comunidade · 🍕 Turma Prova'), findsOneWidget);
  });

  testWidgets('do backlog, "Propor esta" chega com a ideia preenchida', (
    tester,
  ) async {
    final api = apiCom(ideias: [trilha]);
    await tester.pumpWidget(appDeTeste(api: api, agora: agora));
    await tester.pumpAndSettle();
    await irPara(tester, '/turmas/turma-1/ideias');
    expect(find.byType(TelaDoBacklog), findsOneWidget);

    await tester.tap(find.text('Propor esta'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDePropor), findsOneWidget);
    expect(textoDe(tester, 'Nome da atividade'), 'Trilha');
    expect(find.text('Ideia de Bia'), findsOneWidget);
  });
}
