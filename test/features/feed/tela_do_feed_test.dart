import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/design/widgets/pilha_de_avatares.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:connactions_app/features/turmas/seletor_de_turma.dart';
import 'package:connactions_app/features/turmas/tela_da_turma.dart';
import 'package:connactions_app/features/turmas/tela_de_entrar_na_turma.dart';
import 'package:connactions_app/features/turmas/tela_de_nova_turma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/preferencias_em_memoria.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

Future<void> abrirFeed(
  WidgetTester tester, {
  FakeApi? api,
  PreferenciasEmMemoria? preferencias,
  CompartilhadorFalso? compartilhador,
}) async {
  await tester.pumpWidget(
    appDeTeste(
      api: api,
      preferencias: preferencias,
      compartilhador: compartilhador,
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(TelaDoFeed), findsOneWidget);
}

Finder naPilula(String texto) => find.descendant(
  of: find.byType(SeletorDeTurma),
  matching: find.text(texto),
);

void main() {
  testWidgets('sem turmas: o vazio com as duas ações', (tester) async {
    await abrirFeed(tester, api: FakeApi(eu: euDeTeste()));

    expect(find.text('Nenhuma turma por aqui ainda'), findsOneWidget);
    expect(
      find.text(
        'Crie uma turma para os seus amigos ou entre numa com o código de convite.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SeletorDeTurma), findsNothing);

    await tester.tap(find.text('Criar turma'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDeNovaTurma), findsOneWidget);
  });

  testWidgets('"Entrar com código" abre a tela de entrar', (tester) async {
    await abrirFeed(tester, api: FakeApi(eu: euDeTeste()));
    await tester.tap(find.text('Entrar com código'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDeEntrarNaTurma), findsOneWidget);
  });

  testWidgets('com turma: pílula, de quem é a vez e os membros', (
    tester,
  ) async {
    await abrirFeed(
      tester,
      api: FakeApi(
        eu: euDeTeste(),
        turmas: [turmaDeTeste(vezDe: bia, totalDeMembros: 2)],
        membrosPor: {
          'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
        },
      ),
    );

    expect(naPilula('Turma do Domingo'), findsOneWidget);
    expect(naPilula('2 membros · vez de Bia'), findsOneWidget);
    expect(find.text('É a vez de Bia propor'), findsOneWidget);
    expect(
      find.text(
        'A primeira atividade da turma aparece aqui quando for lançada.',
      ),
      findsOneWidget,
    );
    expect(find.text('2 membros'), findsOneWidget);
    expect(find.byType(PilhaDeAvatares), findsOneWidget);
    expect(find.text('Nenhuma turma por aqui ainda'), findsNothing);
  });

  testWidgets('quando a vez é minha, o cartão fala comigo', (tester) async {
    await abrirFeed(
      tester,
      api: FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
    );
    expect(find.text('É a sua vez de propor!'), findsOneWidget);
  });

  testWidgets('erro ao listar mostra tentar de novo e recupera', (
    tester,
  ) async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      falhaAoListarTurmas: const ErroDeRede('caiu'),
    );
    await abrirFeed(tester, api: api);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );

    api.falhaAoListarTurmas = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(naPilula('Turma do Domingo'), findsOneWidget);
  });

  testWidgets('carregando mostra o indicador', (tester) async {
    final api = FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()])
      ..segurarListarTurmas = Completer<void>();
    await tester.pumpWidget(appDeTeste(api: api));
    // sem pumpAndSettle: a lista está presa e o indicador gira para sempre
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    api.segurarListarTurmas!.complete();
    await tester.pumpAndSettle();
    expect(naPilula('Turma do Domingo'), findsOneWidget);
  });

  testWidgets('"Convidar amigos" compartilha o convite com o código', (
    tester,
  ) async {
    final compartilhador = CompartilhadorFalso();
    await abrirFeed(
      tester,
      api: FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
      compartilhador: compartilhador,
    );

    await tester.tap(find.text('Convidar amigos'));
    await tester.pumpAndSettle();

    expect(compartilhador.textos.single, contains('ABCD2345'));
  });

  testWidgets('tocar no cartão dos membros abre a turma', (tester) async {
    await abrirFeed(
      tester,
      api: FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
    );
    await tester.tap(find.text('1 membro'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDaTurma), findsOneWidget);
  });

  testWidgets('abre com a turma salva nas preferências', (tester) async {
    await abrirFeed(
      tester,
      api: FakeApi(
        eu: euDeTeste(),
        turmas: [
          turmaDeTeste(id: 'turma-1'),
          turmaDeTeste(id: 'turma-2', nome: 'Cozinha & Prosa', emoji: '☕'),
        ],
      ),
      preferencias: PreferenciasEmMemoria({'turma_ativa_id': 'turma-2'}),
    );
    expect(naPilula('Cozinha & Prosa'), findsOneWidget);
    expect(naPilula('Turma do Domingo'), findsNothing);
  });

  testWidgets('id salvo de turma que não existe cai na primeira', (
    tester,
  ) async {
    await abrirFeed(
      tester,
      api: FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
      preferencias: PreferenciasEmMemoria({'turma_ativa_id': 'turma-99'}),
    );
    expect(naPilula('Turma do Domingo'), findsOneWidget);
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrirFeed(
      tester,
      api: FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
    );
    final scaffold = find.descendant(
      of: find.byType(TelaDoFeed),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });
}
