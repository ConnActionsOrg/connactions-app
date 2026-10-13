import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/features/atividades/tela_de_propor.dart';
import 'package:connactions_app/features/comunidade/tela_da_comunidade.dart';
import 'package:connactions_app/features/turmas/folha_de_turmas.dart';
import 'package:connactions_app/features/turmas/seletor_de_turma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();
final agora = DateTime.utc(2026, 10, 6, 22);

FakeApi apiCom({
  List<AtividadeDaComunidade>? comunidade,
  List<Ideia> ideias = const [],
  Pessoa? vezDe,
  Atividade? aberta,
  bool semTurma = false,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: semTurma
      ? const []
      : [
          turmaDeTeste(vezDe: vezDe, totalDeMembros: 2),
          turmaDeTeste(
            id: 'turma-2',
            nome: 'Outra turma',
            emoji: '🎲',
            codigoConvite: 'ZZZZ2345',
          ),
        ],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  abertaPor: {'turma-1': aberta},
  ideiasPor: {'turma-1': ideias},
  comunidade: comunidade ?? [atividadeDaComunidadeDeTeste()],
);

/// Tela alta; o puxar para atualizar pede o viewport padrão, porque só dispara depois de arrastar
/// 25% da altura da tela.
Future<void> abrirComunidade(
  WidgetTester tester,
  FakeApi api, {
  Size tamanho = const Size(800, 2400),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(appDeTeste(api: api, agora: agora));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Comunidade'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDaComunidade), findsOneWidget);
}

Finder naTela(Finder f) =>
    find.descendant(of: find.byType(TelaDaComunidade), matching: f);

int leituras(FakeApi api, String chamada) =>
    api.chamadas.where((c) => c.startsWith(chamada)).length;

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('com turma: a pílula e o cartão da Comunidade com as ações', (
    tester,
  ) async {
    await abrirComunidade(tester, apiCom());

    expect(naTela(find.byType(SeletorDeTurma)), findsOneWidget);
    expect(naTela(find.text('Noite de jogos')), findsOneWidget);
    expect(naTela(find.text('Salvar no backlog 0/5')), findsOneWidget);
    expect(naTela(find.text('Propor pro meu grupo')), findsOneWidget);
  });

  testWidgets('sem turma: a faixa, o cartão para ler e nenhuma ação', (
    tester,
  ) async {
    await abrirComunidade(tester, apiCom(semTurma: true));

    expect(
      naTela(find.text('Entre numa turma para guardar ideias e propor.')),
      findsOneWidget,
    );
    expect(naTela(find.byType(SeletorDeTurma)), findsNothing);
    expect(naTela(find.text('Noite de jogos')), findsOneWidget);
    expect(naTela(find.textContaining('Salvar no backlog')), findsNothing);
    expect(naTela(find.text('Propor pro meu grupo')), findsNothing);
  });

  testWidgets('salvar vira "Salva ✓" com o contador e avisa com a turma', (
    tester,
  ) async {
    final api = apiCom();
    await abrirComunidade(tester, api);

    await tester.tap(naTela(find.text('Salvar no backlog 0/5')));
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('salvarDaComunidade:com-1:turma-1'));
    expect(naTela(find.text('Salva ✓ 1/5')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.ancestor(
              of: naTela(find.text('Salva ✓ 1/5')),
              matching: find.byWidgetPredicate((w) => w is OutlinedButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text('Ideia salva no backlog de 🌿 Turma do Domingo'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'salvar em voo: o segundo toque não chama a API e o botão avisa',
    (tester) async {
      final segurar = Completer<void>();
      final api = apiCom()..segurarSalvarDaComunidade = segurar;
      await abrirComunidade(tester, api);

      await tester.tap(naTela(find.text('Salvar no backlog 0/5')));
      await tester.pump();
      await tester.tap(
        naTela(find.text('Salvar no backlog 0/5')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(leituras(api, 'salvarDaComunidade'), 1);
      expect(
        tester
            .widget<OutlinedButton>(
              find.descendant(
                of: find.byType(TelaDaComunidade),
                matching: find.byWidgetPredicate((w) => w is OutlinedButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        naTela(find.byType(CircularProgressIndicator)),
        findsOneWidget,
        reason: 'o ícone vira o indicador de progresso enquanto salva',
      );

      segurar.complete();
      await tester.pumpAndSettle();

      expect(
        find.text('Ideia salva no backlog de 🌿 Turma do Domingo'),
        findsOneWidget,
      );
      expect(
        find.text('Essa ideia já está no backlog da turma.'),
        findsNothing,
      );
      expect(naTela(find.text('Salva ✓ 1/5')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('já guardada na ativa: nasce "Salva ✓" e desligada', (
    tester,
  ) async {
    await abrirComunidade(
      tester,
      apiCom(ideias: [ideiaDeTeste(origemAtividadeId: 'com-1')]),
    );

    expect(naTela(find.text('Salva ✓ 1/5')), findsOneWidget);
  });

  testWidgets('o 409 de backlog cheio avisa e relê as ideias da ativa', (
    tester,
  ) async {
    final api = apiCom()
      ..falhaAoSalvarDaComunidade = const ErroDaApi(
        status: 409,
        codigo: 'backlog_cheio',
        mensagem: 'Você já tem 5 ideias guardadas nesta turma.',
      );
    await abrirComunidade(tester, api);
    expect(leituras(api, 'listarIdeias'), 1);

    await tester.tap(naTela(find.text('Salvar no backlog 0/5')));
    await tester.pumpAndSettle();

    expect(
      find.text('Você já tem 5 ideias guardadas nesta turma.'),
      findsOneWidget,
    );
    expect(leituras(api, 'listarIdeias'), 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('o 404 (entrei na turma dela) avisa e relê a Comunidade', (
    tester,
  ) async {
    final api = apiCom()
      ..falhaAoSalvarDaComunidade = const ErroDaApi(
        status: 404,
        codigo: 'nao_encontrado',
        mensagem: 'Não encontramos o que você procura.',
      );
    await abrirComunidade(tester, api);
    expect(leituras(api, 'listarComunidade'), 1);

    await tester.tap(naTela(find.text('Salvar no backlog 0/5')));
    await tester.pumpAndSettle();

    expect(find.text('Não encontramos o que você procura.'), findsOneWidget);
    expect(leituras(api, 'listarComunidade'), 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('o 403 avisa e relê as turmas', (tester) async {
    final api = apiCom()
      ..falhaAoSalvarDaComunidade = const ErroDaApi(
        status: 403,
        codigo: 'sem_acesso',
        mensagem: 'Você não faz parte desta turma.',
      );
    await abrirComunidade(tester, api);
    expect(leituras(api, 'listarTurmas'), 1);

    await tester.tap(naTela(find.text('Salvar no backlog 0/5')));
    await tester.pumpAndSettle();

    expect(find.text('Você não faz parte desta turma.'), findsOneWidget);
    expect(leituras(api, 'listarTurmas'), 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('"Propor pro meu grupo" abre o Propor preenchido', (
    tester,
  ) async {
    await abrirComunidade(tester, apiCom());

    await tester.tap(naTela(find.text('Propor pro meu grupo')));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDePropor), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.widgetWithText(TextField, 'Nome da atividade'),
          )
          .controller!
          .text,
      'Noite de jogos',
    );
    expect(find.text('Da Comunidade · 🍕 Turma Prova'), findsOneWidget);
  });

  testWidgets('"Propor pro meu grupo" some fora da vez', (tester) async {
    await abrirComunidade(tester, apiCom(vezDe: bia));

    expect(naTela(find.text('Noite de jogos')), findsOneWidget);
    expect(naTela(find.text('Propor pro meu grupo')), findsNothing);
    expect(naTela(find.textContaining('Salvar no backlog')), findsOneWidget);
  });

  testWidgets('"Propor pro meu grupo" some com atividade aberta', (
    tester,
  ) async {
    await abrirComunidade(tester, apiCom(aberta: atividadeDeTeste()));

    expect(naTela(find.text('Noite de jogos')), findsOneWidget);
    expect(naTela(find.text('Propor pro meu grupo')), findsNothing);
  });

  testWidgets('trocar a turma ativa troca o contador e o "Salva ✓"', (
    tester,
  ) async {
    await abrirComunidade(
      tester,
      apiCom(ideias: [ideiaDeTeste(origemAtividadeId: 'com-1')]),
    );
    expect(naTela(find.text('Salva ✓ 1/5')), findsOneWidget);

    await tester.tap(naTela(find.byType(SeletorDeTurma)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FolhaDeTurmas),
        matching: find.text('Outra turma'),
      ),
    );
    await tester.pumpAndSettle();

    expect(naTela(find.text('Salvar no backlog 0/5')), findsOneWidget);
    expect(naTela(find.text('Salva ✓ 1/5')), findsNothing);
  });

  testWidgets('vazio: a comunidade quieta', (tester) async {
    await abrirComunidade(tester, apiCom(comunidade: const []));

    expect(naTela(find.text('A comunidade ainda está quieta')), findsOneWidget);
  });

  testWidgets('erro: tentar de novo traz a lista', (tester) async {
    final api = apiCom()..falhaAoListarComunidade = const ErroDeRede('caiu');
    await abrirComunidade(tester, api);
    expect(naTela(find.text('Algo não deu certo')), findsOneWidget);

    api.falhaAoListarComunidade = null;
    await tester.tap(naTela(find.text('Tentar de novo')));
    await tester.pumpAndSettle();

    expect(naTela(find.text('Noite de jogos')), findsOneWidget);
  });

  testWidgets('erro nas turmas: tentar de novo relê a cadeia, não só a lista', (
    tester,
  ) async {
    final api = apiCom()..falhaAoListarTurmas = const ErroDeRede('caiu');
    await abrirComunidade(tester, api);
    expect(naTela(find.text('Algo não deu certo')), findsOneWidget);

    api.falhaAoListarTurmas = null;
    await tester.tap(naTela(find.text('Tentar de novo')));
    await tester.pumpAndSettle();

    expect(naTela(find.text('Noite de jogos')), findsOneWidget);
  });

  testWidgets('"Carregar mais" traz a página seguinte', (tester) async {
    final api = apiCom(
      comunidade: [
        for (var i = 1; i <= 22; i++)
          atividadeDaComunidadeDeTeste(id: 'com-$i', titulo: 'Atividade $i'),
      ],
    );
    await abrirComunidade(tester, api);
    final lista = naTela(find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(
      find.text('Carregar mais'),
      300,
      scrollable: lista,
    );
    // o botão pode ficar sob a barra de abas: `ensureVisible` rola até ele de verdade
    await tester.ensureVisible(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Atividade 22'),
      300,
      scrollable: lista,
    );
    expect(find.text('Atividade 22'), findsOneWidget);
    expect(find.text('Carregar mais', skipOffstage: false), findsNothing);
  });

  testWidgets('puxar para baixo relê a Comunidade e as ideias da ativa', (
    tester,
  ) async {
    final api = apiCom();
    await abrirComunidade(tester, api, tamanho: const Size(800, 600));
    expect(leituras(api, 'listarComunidade'), 1);
    expect(leituras(api, 'listarIdeias'), 1);

    await tester.fling(
      naTela(find.byType(ListView)).first,
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(leituras(api, 'listarComunidade'), 2);
    expect(leituras(api, 'listarIdeias'), 2);
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrirComunidade(tester, apiCom());
    final scaffold = find.descendant(
      of: find.byType(TelaDaComunidade),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });
}
