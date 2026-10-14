import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/features/diario/cartao_da_capa.dart';
import 'package:connactions_app/features/diario/folha_de_personalizar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';

/// Segura `personalizarDiario` até o teste liberar: prova o estado de enviando sem depender de timing.
class _ApiComPatchSegurado extends FakeApi {
  _ApiComPatchSegurado({super.eu, super.turmas});

  final liberar = Completer<void>();
  var pedidos = 0;

  @override
  Future<CapaDoDiario> personalizarDiario(
    String turmaId,
    AlteracoesDaCapa alteracoes,
  ) async {
    pedidos++; // conta antes de segurar: o toque repetido chegaria aqui
    await liberar.future;
    return super.personalizarDiario(turmaId, alteracoes);
  }
}

FakeApi apiCom({CapaDoDiario? capa}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  capaPor: {'turma-1': ?capa},
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  // A folha é alta: sem tela alta, os toques caem fora dela.
  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> abrirFolha(WidgetTester tester, FakeApi api) async {
    telaAlta(tester);
    await tester.pumpWidget(
      appDeTeste(api: api, agora: DateTime.utc(2026, 10, 20, 12)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Personalizar o diário'));
    await tester.pumpAndSettle();
  }

  Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);
  Finder salvar() => find.widgetWithText(FilledButton, 'Salvar');
  bool salvarHabilitado(WidgetTester tester) =>
      tester.widget<FilledButton>(salvar()).onPressed != null;

  testWidgets('a capa aparece no topo do Diário, também com a lista vazia', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(
      appDeTeste(api: apiCom(), agora: DateTime.utc(2026, 10, 20, 12)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();

    expect(find.byType(CartaoDaCapa), findsOneWidget);
    expect(find.text('Diário de 🌿 Turma do Domingo'), findsOneWidget);
    expect(find.text('O diário da turma começa vazio'), findsOneWidget);
  });

  testWidgets(
    'a folha abre com o que está gravado e Salvar começa desabilitado',
    (tester) async {
      await abrirFolha(
        tester,
        apiCom(
          capa: capaDeTeste(
            titulo: 'Noites de quinta',
            frase: 'Quem não vem, perde a pizza.',
            sticker: StickerDoDiario.pizza,
          ),
        ),
      );

      expect(find.byType(FolhaDePersonalizar), findsOneWidget);
      expect(
        tester.widget<TextField>(campo('Título')).controller!.text,
        'Noites de quinta',
      );
      expect(
        tester.widget<TextField>(campo('Frase da capa')).controller!.text,
        'Quem não vem, perde a pizza.',
      );
      expect(salvarHabilitado(tester), isFalse);
    },
  );

  testWidgets(
    'trocar só a paleta e o sticker manda só isso, e a capa da tela muda',
    (tester) async {
      final api = apiCom(capa: capaDeTeste(titulo: 'Noites de quinta'));
      await abrirFolha(tester, api);

      await tester.tap(find.byTooltip('Paleta Terracota'));
      await tester.tap(find.byTooltip('Sticker Pizza'));
      await tester.pump();
      expect(salvarHabilitado(tester), isTrue);
      await tester.tap(salvar());
      await tester.pumpAndSettle();

      expect(api.ultimaAlteracaoDaCapa!.toJson(), {
        'paleta': 'terracota',
        'sticker': 'pizza',
      });
      expect(find.byType(FolhaDePersonalizar), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CartaoDaCapa),
          matching: find.text('🍕'),
        ),
        findsOneWidget,
      );
      expect(find.text('Noites de quinta'), findsOneWidget);
    },
  );

  testWidgets('título e frase apagados voltam ao padrão', (tester) async {
    final api = apiCom(
      capa: capaDeTeste(titulo: 'Noites de quinta', frase: 'Pizza'),
    );
    await abrirFolha(tester, api);

    await tester.enterText(campo('Título'), '   ');
    await tester.enterText(campo('Frase da capa'), '');
    await tester.pump();
    await tester.tap(salvar());
    await tester.pumpAndSettle();

    expect(api.ultimaAlteracaoDaCapa!.toJson(), {'titulo': '', 'frase': ''});
    expect(api.capaPor['turma-1']!.titulo, isNull);
    expect(find.text('Diário de 🌿 Turma do Domingo'), findsOneWidget);
    expect(find.text('Pizza'), findsNothing);
  });

  testWidgets('desfazer a mudança desabilita Salvar de novo', (tester) async {
    await abrirFolha(tester, apiCom());

    await tester.tap(find.byTooltip('Sticker Praia'));
    await tester.pump();
    expect(salvarHabilitado(tester), isTrue);
    await tester.tap(
      find.byTooltip('Sticker Livro'),
    ); // o que já estava gravado
    await tester.pump();
    expect(salvarHabilitado(tester), isFalse);

    await tester.enterText(campo('Título'), 'Novo');
    await tester.pump();
    expect(salvarHabilitado(tester), isTrue);
    await tester.enterText(campo('Título'), '');
    await tester.pump();
    expect(salvarHabilitado(tester), isFalse);
  });

  testWidgets(
    'na falha a folha fica aberta, com o que foi digitado e a mensagem',
    (tester) async {
      final api = apiCom()..falhaAoPersonalizar = const ErroDeRede('caiu');
      await abrirFolha(tester, api);

      await tester.enterText(campo('Título'), 'Noites de quinta');
      await tester.pump();
      await tester.tap(salvar());
      await tester.pumpAndSettle();

      expect(find.byType(FolhaDePersonalizar), findsOneWidget);
      expect(
        tester.widget<TextField>(campo('Título')).controller!.text,
        'Noites de quinta',
      );
      expect(
        find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
        findsOneWidget,
      );
      expect(salvarHabilitado(tester), isTrue);

      // digitar de novo limpa a mensagem; com a rede de volta, salva
      api.falhaAoPersonalizar = null;
      await tester.enterText(campo('Título'), 'Noites de quinta!');
      await tester.pump();
      expect(find.textContaining('Sem conexão'), findsNothing);
      await tester.tap(salvar());
      await tester.pumpAndSettle();
      expect(find.byType(FolhaDePersonalizar), findsNothing);
      expect(find.text('Noites de quinta!'), findsOneWidget);
    },
  );

  testWidgets('a mensagem da API (título comprido demais) aparece na folha', (
    tester,
  ) async {
    final api = apiCom();
    await abrirFolha(tester, api);

    // o campo limita a 40, mas o teto do servidor é em caracteres e não em grafemas: 40 bandeiras são 80 runas
    await tester.enterText(campo('Título'), '🇧🇷' * 40);
    await tester.pump();
    await tester.tap(salvar());
    await tester.pumpAndSettle();

    expect(find.byType(FolhaDePersonalizar), findsOneWidget);
    expect(find.text('O título pode ter até 40 caracteres.'), findsOneWidget);
  });

  testWidgets(
    'fechar a folha com o PATCH em voo ainda troca a capa do cartão',
    (tester) async {
      final api = _ApiComPatchSegurado(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
      );
      await abrirFolha(tester, api);

      await tester.tap(find.byTooltip('Sticker Pizza'));
      await tester.pump();
      await tester.tap(salvar());
      await tester.pump();

      // dispensa a folha tocando na área escura, fora dela
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(FolhaDePersonalizar), findsNothing);

      api.liberar.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(CartaoDaCapa),
          matching: find.text('🍕'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('enquanto envia, o botão mostra progresso e ignora novo toque', (
    tester,
  ) async {
    final api = _ApiComPatchSegurado(eu: euDeTeste(), turmas: [turmaDeTeste()]);
    await abrirFolha(tester, api);

    await tester.tap(find.byTooltip('Sticker Praia'));
    await tester.pump();
    await tester.tap(salvar());
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(api.pedidos, 1);

    api.liberar.complete();
    await tester.pumpAndSettle();
    expect(find.byType(FolhaDePersonalizar), findsNothing);
  });
}
