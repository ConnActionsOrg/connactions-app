import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/features/atividades/atividade_aberta.dart';
import 'package:connactions_app/features/atividades/tela_de_propor.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();
// local, não UTC: o prazo é 23:59:59 do dia escolhido no fuso do aparelho
final agora = DateTime(2026, 9, 29, 12);

FakeApi apiMinhaVez({Object? falhaAoLancar}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  falhaAoLancar: falhaAoLancar,
);

Future<void> abrirPeloFeed(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api, agora: agora));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Propor atividade'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDePropor), findsOneWidget);
}

Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

String textoDe(WidgetTester tester, String rotulo) =>
    tester.widget<TextField>(campo(rotulo)).controller!.text;

FilledButton botaoLancar(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Lançar atividade'),
);

int leituras(FakeApi api, String chamada) =>
    api.chamadas.where((c) => c.startsWith(chamada)).length;

/// Rola a lista da tela. Cada `TextField` traz um `Scrollable` próprio, que vem depois dela na
/// árvore: `.last` pegaria o de um campo.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  final lista = find
      .descendant(
        of: find.byType(TelaDePropor),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(alvo, 200, scrollable: lista);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('regrasDoTexto parte por linha, apara e descarta vazias', () {
    expect(regrasDoTexto(' Um item \n\n  \nDois itens\n'), [
      'Um item',
      'Dois itens',
    ]);
    expect(regrasDoTexto(''), isEmpty);
  });

  testWidgets('abre pelo Feed com o herói e Lançar desabilitado', (
    tester,
  ) async {
    await abrirPeloFeed(tester, apiMinhaVez());
    expect(find.text('É a sua vez de propor!'), findsOneWidget);
    expect(find.text('O que vamos fazer?'), findsOneWidget);
    await rolarAte(tester, find.text('Lançar atividade'));
    expect(botaoLancar(tester).onPressed, isNull);
  });

  testWidgets(
    'lança com título, descrição, regras, individual e privada; volta ao Feed',
    (tester) async {
      final api = apiMinhaVez();
      await abrirPeloFeed(tester, api);

      await tester.enterText(campo('Nome da atividade'), 'Noite de jogos');
      await tester.enterText(
        campo('Como vai funcionar?'),
        'Cada um leva um jogo.',
      );
      await tester.enterText(
        campo('Regras (opcional), uma por linha'),
        'Um jogo\n\nSem celular',
      );
      await tester.pump();
      await rolarAte(tester, find.text('Individual'));
      await tester.tap(find.text('Individual'));
      await tester.pump();
      await rolarAte(tester, find.text('Permitir na Comunidade'));
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await rolarAte(tester, find.text('Lançar atividade'));
      expect(botaoLancar(tester).onPressed, isNotNull);

      await tester.tap(find.text('Lançar atividade'));
      await tester.pumpAndSettle();

      expect(api.chamadas.last, 'lancarAtividade:turma-1:Noite de jogos');
      final lancada = api.abertaPor['turma-1']!;
      expect(lancada.descricao, 'Cada um leva um jogo.');
      expect(lancada.regras, ['Um jogo', 'Sem celular']);
      expect(lancada.formato, FormatoDeAtividade.individual);
      expect(lancada.publica, isFalse);
      expect(lancada.prazo, isNull);
      expect(find.byType(TelaDePropor), findsNothing);
      expect(find.byType(TelaDoFeed), findsOneWidget);
      expect(find.text('Você propôs a rodada 1'), findsOneWidget);
      expect(find.text('Atividade lançada!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('padrões: em grupo, sem pressa, pública', (tester) async {
    final api = apiMinhaVez();
    await abrirPeloFeed(tester, api);
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();
    await rolarAte(tester, find.text('Lançar atividade'));
    await tester.tap(find.text('Lançar atividade'));
    await tester.pumpAndSettle();

    final lancada = api.abertaPor['turma-1']!;
    expect(lancada.formato, FormatoDeAtividade.grupo);
    expect(lancada.publica, isTrue);
    expect(lancada.prazo, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'definir data marca 23:59:59 do dia escolhido no fuso do aparelho',
    (tester) async {
      final api = apiMinhaVez();
      await abrirPeloFeed(tester, api);
      await tester.enterText(campo('Nome da atividade'), 'Piquenique');
      await tester.pump();
      await rolarAte(tester, find.text('Definir data'));
      await tester.tap(find.text('Definir data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // a data inicial do seletor é hoje
      await tester.pumpAndSettle();
      expect(find.textContaining('até '), findsOneWidget);

      await rolarAte(tester, find.text('Lançar atividade'));
      await tester.tap(find.text('Lançar atividade'));
      await tester.pumpAndSettle();

      final prazo = api.abertaPor['turma-1']!.prazo!;
      expect(prazo.hour, 23);
      expect(prazo.minute, 59);
      expect(prazo.second, 59);
      expect(prazo.day, agora.day);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('onze regras travam o botão com erro no campo', (tester) async {
    await abrirPeloFeed(tester, apiMinhaVez());
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.enterText(
      campo('Regras (opcional), uma por linha'),
      List.generate(11, (i) => 'regra $i').join('\n'),
    );
    await tester.pump();
    expect(find.text('No máximo 10 regras.'), findsOneWidget);
    await rolarAte(tester, find.text('Lançar atividade'));
    expect(botaoLancar(tester).onPressed, isNull);
  });

  testWidgets('409 avisa, recarrega e volta ao Feed', (tester) async {
    final api = apiMinhaVez(
      falhaAoLancar: const ErroDaApi(
        status: 409,
        codigo: 'nao_e_sua_vez',
        mensagem: 'Ainda não é a sua vez de propor nesta turma.',
      ),
    );
    await abrirPeloFeed(tester, api);
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();
    await rolarAte(tester, find.text('Lançar atividade'));
    final turmasLidas = leituras(api, 'listarTurmas');
    final abertasLidas = leituras(api, 'obterAtividadeAberta');
    await tester.tap(find.text('Lançar atividade'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDePropor), findsNothing);
    expect(
      find.text('Ainda não é a sua vez de propor nesta turma.'),
      findsOneWidget,
    );
    expect(leituras(api, 'listarTurmas'), turmasLidas + 1);
    expect(leituras(api, 'obterAtividadeAberta'), abertasLidas + 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('422 (prazo virou passado) avisa e o rascunho fica', (
    tester,
  ) async {
    await abrirPeloFeed(
      tester,
      apiMinhaVez(
        falhaAoLancar: const ErroDaApi(
          status: 422,
          codigo: 'dados_invalidos',
          mensagem: 'O prazo precisa estar no futuro.',
        ),
      ),
    );
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();
    await rolarAte(tester, find.text('Lançar atividade'));
    await tester.tap(find.text('Lançar atividade'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDePropor), findsOneWidget);
    expect(find.text('O prazo precisa estar no futuro.'), findsOneWidget);
    expect(
      tester.widget<TextField>(campo('Nome da atividade')).controller!.text,
      'Piquenique',
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'aberta fora da minha vez ou com atividade aberta: estado vazio',
    (tester) async {
      await tester.pumpWidget(
        appDeTeste(
          api: FakeApi(
            eu: euDeTeste(),
            turmas: [turmaDeTeste(vezDe: bia)],
          ),
          agora: agora,
        ),
      );
      await tester.pumpAndSettle();
      await irPara(tester, '/turmas/turma-1/propor');
      expect(find.text('Ainda não é a sua vez'), findsOneWidget);
      expect(find.text('Lançar atividade'), findsNothing);

      await tester.pumpWidget(
        appDeTeste(
          api: FakeApi(
            eu: euDeTeste(),
            turmas: [turmaDeTeste()],
            abertaPor: {'turma-1': atividadeDeTeste()},
          ),
          agora: agora,
        ),
      );
      await tester.pumpAndSettle();
      await irPara(tester, '/turmas/turma-1/propor');
      expect(find.text('Ainda não é a sua vez'), findsOneWidget);
    },
  );

  testWidgets('sem conexão avisa e o rascunho fica com o botão de volta', (
    tester,
  ) async {
    await abrirPeloFeed(
      tester,
      apiMinhaVez(falhaAoLancar: const ErroDeRede('sem rede')),
    );
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();
    await rolarAte(tester, find.text('Lançar atividade'));
    await tester.tap(find.text('Lançar atividade'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDePropor), findsOneWidget);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(textoDe(tester, 'Nome da atividade'), 'Piquenique');
    expect(botaoLancar(tester).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'enquanto lança, o botão mostra o progresso e não dispara de novo',
    (tester) async {
      final api = apiMinhaVez();
      await abrirPeloFeed(tester, api);
      await tester.enterText(campo('Nome da atividade'), 'Piquenique');
      await tester.pump();
      await rolarAte(tester, find.text('Lançar atividade'));
      // a leitura da aberta pendura, e com ela o lancar, que a espera antes de chamar a API
      // (só depois de abrir: o Feed por baixo também a lê e não assentaria)
      final segurar = api.segurarObterAberta = Completer<void>();
      ProviderScope.containerOf(
        tester.element(find.byType(TelaDePropor)),
      ).invalidate(atividadeAbertaProvider('turma-1'));
      await tester.pump();

      await tester.tap(find.text('Lançar atividade'));
      await tester.pump();

      final tela = find.byType(TelaDePropor);
      final botao = find.descendant(
        of: tela,
        matching: find.byType(FilledButton),
      );
      expect(
        find.descendant(
          of: botao,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text('Lançar atividade'), findsNothing);
      expect(tester.widget<FilledButton>(botao).onPressed, isNull);
      await tester.tap(botao, warnIfMissed: false);

      segurar.complete();
      await tester.pumpAndSettle();

      expect(leituras(api, 'lancarAtividade'), 1);
      expect(tela, findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'título com emoji passa do teto em runes: a API recusa e o rascunho fica',
    (tester) async {
      await abrirPeloFeed(
        tester,
        apiMinhaVez(
          falhaAoLancar: const ErroDaApi(
            status: 422,
            codigo: 'dados_invalidos',
            mensagem: 'O título precisa ter de 1 a 80 caracteres.',
          ),
        ),
      );

      // o campo conta o que se vê, não os bytes
      await tester.enterText(campo('Nome da atividade'), 'a' * 81);
      expect(textoDe(tester, 'Nome da atividade'), hasLength(80));
      // uma família é um único caractere visível e 7 runes
      const familia = '\u{1F468}‍\u{1F469}‍\u{1F467}‍\u{1F466}';
      expect(familia.runes, hasLength(7));
      await tester.enterText(campo('Nome da atividade'), familia * 30);
      await tester.pump();
      expect(textoDe(tester, 'Nome da atividade'), familia * 30);

      await rolarAte(tester, find.text('Lançar atividade'));
      await tester.tap(find.text('Lançar atividade'));
      await tester.pumpAndSettle();

      expect(find.byType(TelaDePropor), findsOneWidget);
      expect(
        find.text('O título precisa ter de 1 a 80 caracteres.'),
        findsOneWidget,
      );
      expect(textoDe(tester, 'Nome da atividade'), familia * 30);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('dez regras de 100 caracteres passam; uma de 101 trava o botão', (
    tester,
  ) async {
    await abrirPeloFeed(tester, apiMinhaVez());
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    final regras = campo('Regras (opcional), uma por linha');

    await tester.enterText(regras, List.filled(10, 'r' * 100).join('\n'));
    await tester.pump();
    expect(find.text('No máximo 10 regras.'), findsNothing);
    expect(find.text('Cada regra tem até 100 caracteres.'), findsNothing);

    await tester.enterText(regras, 'r' * 101);
    await tester.pump();
    expect(find.text('Cada regra tem até 100 caracteres.'), findsOneWidget);
    await rolarAte(tester, find.text('Lançar atividade'));
    expect(botaoLancar(tester).onPressed, isNull);
  });

  testWidgets(
    'a regra conta runes, não unidades UTF-16: 51 emojis passam e 101 travam',
    (tester) async {
      await abrirPeloFeed(tester, apiMinhaVez());
      await tester.enterText(campo('Nome da atividade'), 'Piquenique');
      final regras = campo('Regras (opcional), uma por linha');

      // 51 emojis são 102 unidades UTF-16, mas 51 runes: é o que a API conta
      await tester.enterText(regras, '😀' * 51);
      await tester.pump();
      expect(find.text('Cada regra tem até 100 caracteres.'), findsNothing);

      await tester.enterText(regras, '😀' * 100);
      await tester.pump();
      expect(find.text('Cada regra tem até 100 caracteres.'), findsNothing);

      await tester.enterText(regras, '😀' * 101);
      await tester.pump();
      expect(find.text('Cada regra tem até 100 caracteres.'), findsOneWidget);
      await rolarAte(tester, find.text('Lançar atividade'));
      expect(botaoLancar(tester).onPressed, isNull);
    },
  );

  testWidgets('Sem pressa desfaz a data escolhida', (tester) async {
    final api = apiMinhaVez();
    await abrirPeloFeed(tester, api);
    await tester.enterText(campo('Nome da atividade'), 'Piquenique');
    await tester.pump();
    await rolarAte(tester, find.text('Definir data'));
    await tester.tap(find.text('Definir data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('até '), findsOneWidget);

    await tester.tap(find.text('Sem pressa'));
    await tester.pump();
    expect(find.textContaining('até '), findsNothing);
    expect(find.text('Definir data'), findsOneWidget);

    await rolarAte(tester, find.text('Lançar atividade'));
    await tester.tap(find.text('Lançar atividade'));
    await tester.pumpAndSettle();
    expect(api.abertaPor['turma-1']!.prazo, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Voltar, no estado vazio, fecha a tela', (tester) async {
    await tester.pumpWidget(
      appDeTeste(
        api: FakeApi(
          eu: euDeTeste(),
          turmas: [turmaDeTeste(vezDe: bia)],
        ),
        agora: agora,
      ),
    );
    await tester.pumpAndSettle();
    await irPara(tester, '/turmas/turma-1/propor');

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDePropor), findsNothing);
    expect(find.byType(TelaDoFeed), findsOneWidget);
  });

  testWidgets('o seletor não deixa escolher um dia que já passou', (
    tester,
  ) async {
    await abrirPeloFeed(tester, apiMinhaVez());
    await rolarAte(tester, find.text('Definir data'));
    await tester.tap(find.text('Definir data'));
    await tester.pumpAndSettle();

    // ontem (28) está desabilitado: o toque não muda a data inicial, que é hoje (29)
    await tester.tap(find.text('28'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('29 de'), findsOneWidget);
  });

  testWidgets('cabe em tela estreita sem estourar', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await abrirPeloFeed(tester, apiMinhaVez());

    // a fonte dos testes tem glifos largos: o que cabe aqui cabe com a fonte de verdade
    await rolarAte(tester, find.text('Lançar atividade'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('título só com espaços não habilita o botão', (tester) async {
    await abrirPeloFeed(tester, apiMinhaVez());
    await tester.enterText(campo('Nome da atividade'), '   ');
    await tester.pump();
    await rolarAte(tester, find.text('Lançar atividade'));
    expect(botaoLancar(tester).onPressed, isNull);
  });

  testWidgets('os cartões de formato e de prazo dizem qual está selecionado', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await abrirPeloFeed(tester, apiMinhaVez());
    bool selecionado(String titulo) =>
        tester
            .getSemantics(find.text(titulo))
            .getSemanticsData()
            .flagsCollection
            .isSelected ==
        Tristate.isTrue;

    await rolarAte(tester, find.text('Individual'));
    expect(selecionado('Em grupo'), isTrue);
    expect(selecionado('Individual'), isFalse);
    await tester.tap(find.text('Individual'));
    await tester.pump();
    expect(selecionado('Em grupo'), isFalse);
    expect(selecionado('Individual'), isTrue);

    await rolarAte(tester, find.text('Definir data'));
    expect(selecionado('Sem pressa'), isTrue);
    expect(selecionado('Definir data'), isFalse);
    // dispose síncrono na última linha: addTearDown dispararia depois da verificação de fim
    semantica.dispose();
  });
}
