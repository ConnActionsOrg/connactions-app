import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/comentario.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/app/relogio.dart';
import 'package:connactions_app/features/diario/folha_de_comentarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

final agora = DateTime.utc(2026, 10, 14, 15);

FakeApi apiCom(List<Comentario> comentarios) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  diarioPor: {
    'turma-1': [
      atividadeDeTeste(id: 'a1', encerradaEm: DateTime.utc(2026, 9, 30)),
    ],
  },
  comentariosPor: {'a1': comentarios},
);

List<Comentario> comentarios(int quantos) => [
  for (var i = 1; i <= quantos; i++)
    comentarioDeTeste(
      id: 'c$i',
      texto: 'Comentário $i',
      criadoEm: agora.subtract(const Duration(hours: 1)),
    ),
];

/// A folha abre por um botão, como no app: o SnackBar, o teclado e a navegação são os de verdade.
Widget harness(FakeApi api) => ProviderScope(
  overrides: [
    apiProvider.overrideWithValue(api),
    relogioProvider.overrideWithValue(() => agora),
  ],
  child: montar(
    Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => mostrarFolhaDeComentarios(
            context,
            turmaId: 'turma-1',
            atividadeId: 'a1',
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  ),
);

void main() {
  // Tela alta por padrão: a folha só ocupa o que precisa, mas os toques caem fora dela se a tela for baixa.
  Future<void> abrir(
    WidgetTester tester,
    FakeApi api, {
    Size tamanho = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(api));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Finder campo() => find.byType(TextField);
  // o campo de texto também rola: a lista é o Scrollable de dentro do ListView
  Finder lista() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;
  Finder enviar() => find.ancestor(
    of: find.byTooltip('Enviar'),
    matching: find.byType(IconButton),
  );
  bool enviarHabilitado(WidgetTester tester) =>
      tester.widget<IconButton>(enviar()).onPressed != null;

  testWidgets('sem comentários: o vazio e o total zerado', (tester) async {
    await abrir(tester, apiCom(const []));

    expect(find.text('Comentários (0)'), findsOneWidget);
    expect(find.text('Ninguém comentou ainda'), findsOneWidget);
    expect(find.byType(FolhaDeComentarios), findsOneWidget);
  });

  testWidgets(
    'lista do mais antigo ao mais novo, com o primeiro nome e o tempo',
    (tester) async {
      await abrir(
        tester,
        apiCom([
          comentarioDeTeste(
            id: 'c1',
            texto: 'Foi demais!',
            criadoEm: agora.subtract(const Duration(hours: 2)),
          ),
          comentarioDeTeste(
            id: 'c2',
            texto: 'Repete mês que vem',
            criadoEm: agora.subtract(const Duration(minutes: 5)),
            autor: pessoaDeTeste(id: 'p9', nome: 'Caio Reis'),
          ),
        ]),
      );

      expect(find.text('Comentários (2)'), findsOneWidget);
      expect(find.text('Foi demais!'), findsOneWidget);
      expect(find.text('Repete mês que vem'), findsOneWidget);
      expect(
        find.textContaining('Bia · há 2 h', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Caio · há 5 min', findRichText: true),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Foi demais!')).dy,
        lessThan(tester.getTopLeft(find.text('Repete mês que vem')).dy),
      );
    },
  );

  testWidgets('só os meus comentários têm o botão de apagar', (tester) async {
    await abrir(
      tester,
      apiCom([
        comentarioDeTeste(id: 'alheio', texto: 'da Bia'),
        comentarioDeTeste(id: 'meu', texto: 'meu', meu: true),
      ]),
    );

    expect(find.byTooltip('Apagar'), findsOneWidget);
  });

  testWidgets(
    'apagar pede confirmação: Cancelar mantém, Apagar tira e abate o total',
    (tester) async {
      final api = apiCom([
        comentarioDeTeste(id: 'meu', texto: 'meu', meu: true),
      ]);
      await abrir(tester, api);

      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      expect(find.text('Apagar seu comentário?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('meu'), findsOneWidget);
      expect(api.chamadas, isNot(contains('apagarComentario:meu')));

      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Apagar'));
      await tester.pumpAndSettle();

      expect(api.chamadas, contains('apagarComentario:meu'));
      expect(find.text('meu'), findsNothing);
      expect(find.text('Comentários (0)'), findsOneWidget);
      expect(find.text('Ninguém comentou ainda'), findsOneWidget);
    },
  );

  testWidgets(
    'falha ao apagar mostra a mensagem na folha e mantém o comentário',
    (tester) async {
      final api = apiCom([
        comentarioDeTeste(id: 'meu', texto: 'meu', meu: true),
      ])..falhaAoApagarComentario = const ErroDeRede('caiu');
      await abrir(tester, api);

      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Apagar'));
      await tester.pumpAndSettle();

      expect(find.text('meu'), findsOneWidget);
      expect(
        find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
        findsOneWidget,
      );
      expect(find.text('Comentários (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'Enviar só habilita com texto de verdade, e comentar põe o meu no fim',
    (tester) async {
      final api = apiCom(comentarios(2));
      await abrir(tester, api);
      expect(enviarHabilitado(tester), isFalse);

      await tester.enterText(campo(), '   ');
      await tester.pump();
      expect(enviarHabilitado(tester), isFalse);

      await tester.enterText(campo(), 'Foi demais!');
      await tester.pump();
      expect(enviarHabilitado(tester), isTrue);
      await tester.tap(enviar());
      await tester.pumpAndSettle();

      expect(api.chamadas, contains('comentar:a1:Foi demais!'));
      expect(find.text('Foi demais!'), findsOneWidget);
      expect(tester.widget<TextField>(campo()).controller!.text, isEmpty);
      expect(find.text('Comentários (3)'), findsOneWidget);
      expect(enviarHabilitado(tester), isFalse);
      // o meu, por último e com o botão de apagar
      expect(find.byTooltip('Apagar'), findsOneWidget);
    },
  );

  testWidgets('enquanto envia, o texto fica no campo e o botão não responde', (
    tester,
  ) async {
    final api = apiCom(const [])..segurarComentar = Completer<void>();
    await abrir(tester, api);

    await tester.enterText(campo(), 'Foi demais!');
    await tester.pump();
    await tester.tap(enviar());
    await tester.pump();

    expect(tester.widget<TextField>(campo()).controller!.text, 'Foi demais!');
    expect(enviarHabilitado(tester), isFalse);
    await tester.tap(enviar(), warnIfMissed: false);
    await tester.pump();
    expect(api.chamadas.where((c) => c.startsWith('comentar:')), hasLength(1));

    api.segurarComentar!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(campo()).controller!.text, isEmpty);
    expect(find.text('Foi demais!'), findsOneWidget);
  });

  testWidgets(
    'falha ao enviar mantém o texto e mostra a mensagem; digitar a limpa',
    (tester) async {
      final api = apiCom(const [])..falhaAoComentar = const ErroDeRede('caiu');
      await abrir(tester, api);

      await tester.enterText(campo(), 'Foi demais!');
      await tester.pump();
      await tester.tap(enviar());
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(campo()).controller!.text, 'Foi demais!');
      expect(
        find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
        findsOneWidget,
      );
      expect(enviarHabilitado(tester), isTrue);
      expect(find.text('Comentários (0)'), findsOneWidget);

      api.falhaAoComentar = null;
      await tester.enterText(campo(), 'Foi demais!!');
      await tester.pump();
      expect(find.textContaining('Sem conexão'), findsNothing);
      await tester.tap(enviar());
      await tester.pumpAndSettle();
      expect(find.text('Foi demais!!'), findsOneWidget);
    },
  );

  testWidgets('a lista pagina de 50 em 50 pelo "Carregar mais"', (
    tester,
  ) async {
    await abrir(tester, apiCom(comentarios(60)));

    await tester.scrollUntilVisible(
      find.text('Carregar mais'),
      300,
      scrollable: lista(),
    );
    expect(find.text('Comentário 50', skipOffstage: false), findsOneWidget);
    expect(find.text('Comentário 51', skipOffstage: false), findsNothing);

    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Comentário 60'),
      300,
      scrollable: lista(),
    );

    expect(find.text('Comentário 60'), findsOneWidget);
    expect(find.text('Carregar mais', skipOffstage: false), findsNothing);
  });

  testWidgets('falha ao carregar a lista oferece "Tentar de novo"', (
    tester,
  ) async {
    final api = apiCom(comentarios(1))
      ..falhaAoListarComentarios = const ErroDeRede('caiu');
    await abrir(tester, api);

    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );

    api.falhaAoListarComentarios = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Comentário 1'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('falha ao carregar com a folha baixa não estoura: o erro rola', (
    tester,
  ) async {
    final api = apiCom(const [])
      ..falhaAoListarComentarios = const ErroDeRede('caiu');
    await abrir(tester, api, tamanho: const Size(800, 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Tentar de novo', skipOffstage: false), findsOneWidget);
  });

  testWidgets('com o teclado aberto, o campo fica acima dele', (tester) async {
    await abrir(tester, apiCom(comentarios(3)), tamanho: const Size(800, 600));

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(tester.getRect(campo()).bottom, lessThanOrEqualTo(600 - 300));
  });
}
