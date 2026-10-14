import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/api/modelos/comentario.dart';
import 'package:connactions_app/api/modelos/reacao.dart';
import 'package:connactions_app/design/cores.dart';
import 'package:connactions_app/features/diario/folha_de_comentarios.dart';
import 'package:connactions_app/features/diario/folha_de_reacoes.dart';
import 'package:connactions_app/features/diario/paleta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';

const coracaoDeOutra = Reacao(
  tipo: TipoDeReacao.coracao,
  total: 1,
  minha: false,
);

FakeApi apiCom({
  List<Reacao> reacoes = const [],
  List<Comentario> comentarios = const [],
  CapaDoDiario? capa,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  diarioPor: {
    'turma-1': [
      atividadeDeTeste(
        id: 'a1',
        titulo: 'Piquenique',
        encerradaEm: DateTime.utc(2026, 10, 15),
      ),
    ],
  },
  reacoesPor: {'a1': reacoes},
  comentariosPor: {'a1': comentarios},
  capaPor: {'turma-1': ?capa},
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  final agora = DateTime.utc(2026, 10, 20, 12);

  Future<void> abrirDiario(WidgetTester tester, FakeApi api) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(appDeTeste(api: api, agora: agora));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'o cartão traz as reações e o total de comentários da atividade',
    (tester) async {
      await abrirDiario(
        tester,
        apiCom(
          reacoes: const [
            Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true),
            Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false),
          ],
          comentarios: [
            comentarioDeTeste(id: 'c1'),
            comentarioDeTeste(id: 'c2'),
          ],
        ),
      );

      expect(find.text('❤️ 2'), findsOneWidget);
      expect(find.text('🔥 1'), findsOneWidget);
      expect(find.byTooltip('2 comentários'), findsOneWidget);
    },
  );

  testWidgets('tocar num chip reage na hora e tocar de novo desmarca', (
    tester,
  ) async {
    final api = apiCom(reacoes: const [coracaoDeOutra]);
    await abrirDiario(tester, api);
    expect(find.text('❤️ 1'), findsOneWidget);

    await tester.tap(find.text('❤️ 1'));
    await tester.pumpAndSettle();
    expect(api.chamadas, contains('reagir:a1:coracao'));
    expect(find.text('❤️ 2'), findsOneWidget);
    expect(find.byTooltip('Coração, 2 reações, marcada'), findsOneWidget);

    await tester.tap(find.text('❤️ 2'));
    await tester.pumpAndSettle();
    expect(api.chamadas, contains('desreagir:a1:coracao'));
    expect(find.text('❤️ 1'), findsOneWidget);
    expect(find.byTooltip('Coração, 1 reação'), findsOneWidget);
  });

  testWidgets('o chip muda antes de a API responder', (tester) async {
    final api = apiCom(reacoes: const [coracaoDeOutra])
      ..segurarReagir = Completer<void>();
    await abrirDiario(tester, api);

    await tester.tap(find.text('❤️ 1'));
    await tester.pump();
    await tester.pump();

    expect(find.text('❤️ 2'), findsOneWidget); // com a chamada ainda presa
    api.segurarReagir!.complete();
    await tester.pumpAndSettle();
    expect(find.text('❤️ 2'), findsOneWidget);
  });

  testWidgets('se a API falha, o chip volta e o aviso explica', (tester) async {
    final api = apiCom(reacoes: const [coracaoDeOutra])
      ..falhaAoReagir = const ErroDeRede('caiu');
    await abrirDiario(tester, api);

    await tester.tap(find.text('❤️ 1'));
    await tester.pumpAndSettle();

    expect(find.text('❤️ 1'), findsOneWidget);
    expect(find.text('❤️ 2'), findsNothing);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
  });

  testWidgets('o "＋" abre os seis tipos e escolher um reage', (tester) async {
    final api = apiCom();
    await abrirDiario(tester, api);

    await tester.tap(find.byTooltip('Reagir'));
    await tester.pumpAndSettle();
    expect(find.byType(FolhaDeReacoes), findsOneWidget);
    await tester.tap(find.byTooltip('Fogo'));
    await tester.pumpAndSettle();

    expect(find.byType(FolhaDeReacoes), findsNothing);
    expect(api.chamadas, contains('reagir:a1:fogo'));
    expect(find.text('🔥 1'), findsOneWidget);
  });

  testWidgets('falha ao reagir pela folha também mostra o aviso na tela', (
    tester,
  ) async {
    final api = apiCom()..falhaAoReagir = const ErroDeRede('caiu');
    await abrirDiario(tester, api);

    await tester.tap(find.byTooltip('Reagir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fogo'));
    await tester.pumpAndSettle();

    expect(find.text('🔥 1'), findsNothing);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
  });

  testWidgets('o chip marcado usa a paleta da capa', (tester) async {
    await abrirDiario(
      tester,
      apiCom(
        reacoes: const [
          Reacao(tipo: TipoDeReacao.coracao, total: 1, minha: true),
        ],
        capa: capaDeTeste(paleta: PaletaDoDiario.terracota),
      ),
    );

    final pilula = tester.widget<Material>(
      find.descendant(
        of: find.byTooltip('Coração, 1 reação, marcada'),
        matching: find.byType(Material),
      ),
    );
    expect(
      pilula.color,
      coresDaPaleta(PaletaDoDiario.terracota, Cores.claras).chipFundo,
    );
  });

  testWidgets(
    'o balão abre os comentários e o total do cartão acompanha o que se posta',
    (tester) async {
      final api = apiCom();
      await abrirDiario(tester, api);
      expect(find.byTooltip('Comentar'), findsOneWidget);

      await tester.tap(find.byTooltip('Comentar'));
      await tester.pumpAndSettle();
      expect(find.byType(FolhaDeComentarios), findsOneWidget);
      expect(find.text('Comentários (0)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Foi demais!');
      await tester.pump();
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('Comentários (1)'), findsOneWidget);

      // fecha a folha pelo fundo escurecido
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();

      expect(find.byType(FolhaDeComentarios), findsNothing);
      expect(find.byTooltip('1 comentário'), findsOneWidget);
      expect(api.chamadas, contains('comentar:a1:Foi demais!'));
    },
  );
}
