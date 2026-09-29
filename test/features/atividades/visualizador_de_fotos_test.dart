import 'dart:async';

import 'package:connactions_app/api/modelos/registro.dart';
import 'package:connactions_app/features/atividades/visualizador_de_fotos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();
final agora = DateTime.utc(2026, 9, 29, 13);

/// Abre pelo `mostrarVisualizadorDeFotos`, como as telas fazem: assim "fechar" volta para a tela
/// de trás em vez de esvaziar o navigator.
Future<void> abrir(
  WidgetTester tester, {
  required List<Registro> registros,
  int indice = 0,
  bool Function(Registro)? podeApagar,
  Future<void> Function(Registro)? aoApagar,
}) async {
  await tester.pumpWidget(
    montar(
      Builder(
        builder: (context) => FilledButton(
          onPressed: () => mostrarVisualizadorDeFotos(
            context,
            registros: registros,
            indiceInicial: indice,
            agora: agora,
            podeApagar: podeApagar,
            aoApagar: aoApagar,
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  expect(find.byType(VisualizadorDeFotos), findsOneWidget);
}

/// Confirma a exclusão de [apagar] com a requisição SEGURADA, desliza até [deslizarPara] e só
/// então conclui a requisição: quem sai da lista é o registro apagado, não o que está na tela.
Future<void> apagarEDeslizar(
  WidgetTester tester, {
  required List<Registro> registros,
  required int indice,
  required int deslizarPara,
  required String apagar,
}) async {
  final concluir = Completer<void>();
  await abrir(
    tester,
    registros: registros,
    indice: indice,
    podeApagar: (r) => r.id == apagar,
    aoApagar: (_) => concluir.future,
  );
  await tester.tap(find.byTooltip('Apagar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Apagar').last);
  await tester.pumpAndSettle();
  final sentido = deslizarPara > indice ? -1.0 : 1.0;
  for (var i = 0; i < (deslizarPara - indice).abs(); i++) {
    await tester.drag(find.byType(PageView), Offset(500 * sentido, 0));
    await tester.pumpAndSettle();
  }
  concluir.complete();
  await tester.pumpAndSettle();
}

/// Dois dedos em torno do centro da foto, com a distância entre eles indo de 2 × [de] a
/// 2 × [ate].
Future<void> pinca(
  WidgetTester tester, {
  required double de,
  required double ate,
}) async {
  final centro = tester.getCenter(find.byType(PageView));
  final esquerdo = await tester.startGesture(centro - Offset(de, 0));
  final direito = await tester.startGesture(centro + Offset(de, 0));
  const passos = 12;
  for (var i = 1; i <= passos; i++) {
    final meia = de + (ate - de) * i / passos;
    await esquerdo.moveTo(centro - Offset(meia, 0));
    await direito.moveTo(centro + Offset(meia, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await esquerdo.up();
  await direito.up();
  await tester.pumpAndSettle();
}

/// A transformação (zoom e deslocamento) que o InteractiveViewer aplica à foto da tela.
Matrix4 transformacaoDaFoto(WidgetTester tester) {
  final transform = find.descendant(
    of: find.byType(InteractiveViewer),
    matching: find.byType(Transform),
  );
  return tester.widget<Transform>(transform.first).transform;
}

void main() {
  testWidgets('mostra a foto pedida, o autor, a legenda e a posição', (
    tester,
  ) async {
    await abrir(
      tester,
      registros: [
        registroDeTeste(id: 'r1', autor: bia, legenda: 'Bolo'),
        registroDeTeste(
          id: 'r2',
          autor: eu,
          legenda: 'Suco',
          criadoEm: DateTime.utc(2026, 9, 29, 11),
        ),
      ],
      indice: 1,
    );
    expect(find.text('2 / 2'), findsOneWidget);
    // as fotos falham igual (400): só o controller mostra em que página o PageView nasceu
    expect(tester.widget<PageView>(find.byType(PageView)).controller?.page, 1);
    expect(find.text('Marina Duarte'), findsOneWidget);
    expect(find.text('Suco · há 2 h'), findsOneWidget);
    expect(find.byTooltip('Apagar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fechar volta para a tela de trás', (tester) async {
    await abrir(
      tester,
      registros: [registroDeTeste(id: 'r1', autor: bia)],
    );
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(VisualizadorDeFotos), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets(
    'apagar só aparece quando pode, pede confirmação e fecha se não sobra foto',
    (tester) async {
      final apagados = <String>[];
      await abrir(
        tester,
        registros: [registroDeTeste(id: 'r2', autor: eu, legenda: 'Suco')],
        podeApagar: (r) => r.autor.id == eu.id,
        aoApagar: (r) async => apagados.add(r.id),
      );
      expect(find.byTooltip('Apagar'), findsOneWidget);

      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      expect(find.text('Apagar seu registro?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(apagados, isEmpty);

      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar').last);
      await tester.pumpAndSettle();
      expect(apagados, ['r2']);
      expect(find.byType(VisualizadorDeFotos), findsNothing);
    },
  );

  testWidgets(
    'apagar com mais fotos fica no visualizador e anda para a vizinha',
    (tester) async {
      await abrir(
        tester,
        registros: [
          registroDeTeste(id: 'r1', autor: eu, legenda: 'Meu'),
          registroDeTeste(id: 'r2', autor: bia, legenda: 'Dela'),
        ],
        podeApagar: (r) => r.autor.id == eu.id,
        aoApagar: (_) async {},
      );
      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar').last);
      await tester.pumpAndSettle();
      expect(find.byType(VisualizadorDeFotos), findsOneWidget);
      expect(find.textContaining('Dela'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.byTooltip('Apagar'), findsNothing);
    },
  );

  testWidgets('falha ao apagar vira aviso e a foto fica', (tester) async {
    await abrir(
      tester,
      registros: [registroDeTeste(id: 'r1', autor: eu, legenda: 'Meu')],
      podeApagar: (_) => true,
      aoApagar: (_) async => throw Exception('caiu'),
    );
    await tester.tap(find.byTooltip('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();
    expect(find.text('Algo deu errado. Tente de novo.'), findsOneWidget);
    expect(find.textContaining('Meu'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'apagar a 1ª e deslizar para a 2ª antes da resposta: sai a 1ª, a 2ª fica',
    (tester) async {
      await apagarEDeslizar(
        tester,
        registros: [
          registroDeTeste(id: 'r1', autor: eu, legenda: 'Meu'),
          registroDeTeste(id: 'r2', autor: bia, legenda: 'Dela'),
          registroDeTeste(id: 'r3', autor: bia, legenda: 'Outra'),
        ],
        indice: 0,
        deslizarPara: 1,
        apagar: 'r1',
      );
      expect(find.textContaining('Meu'), findsNothing);
      expect(find.textContaining('Dela'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
    },
  );

  testWidgets(
    'apagar a 2ª e deslizar para a 3ª antes da resposta: sai a 2ª, a 3ª fica',
    (tester) async {
      await apagarEDeslizar(
        tester,
        registros: [
          registroDeTeste(id: 'r1', autor: bia, legenda: 'Um'),
          registroDeTeste(id: 'r2', autor: eu, legenda: 'Meu'),
          registroDeTeste(id: 'r3', autor: bia, legenda: 'Tres'),
        ],
        indice: 1,
        deslizarPara: 2,
        apagar: 'r2',
      );
      expect(find.textContaining('Meu'), findsNothing);
      expect(find.textContaining('Tres'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets(
    'apagar a 2ª e voltar para a 1ª antes da resposta: sai a 2ª, a 1ª fica',
    (tester) async {
      await apagarEDeslizar(
        tester,
        registros: [
          registroDeTeste(id: 'r1', autor: bia, legenda: 'Um'),
          registroDeTeste(id: 'r2', autor: eu, legenda: 'Meu'),
          registroDeTeste(id: 'r3', autor: bia, legenda: 'Tres'),
        ],
        indice: 1,
        deslizarPara: 0,
        apagar: 'r2',
      );
      expect(find.textContaining('Meu'), findsNothing);
      expect(find.textContaining('Um'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
    },
  );

  testWidgets('ampliada, o arrasto move a foto e não troca de página', (
    tester,
  ) async {
    await abrir(
      tester,
      registros: [
        registroDeTeste(id: 'r1', autor: eu),
        registroDeTeste(id: 'r2', autor: bia),
      ],
    );
    await pinca(tester, de: 30, ate: 174);
    expect(transformacaoDaFoto(tester).getMaxScaleOnAxis(), greaterThan(1.5));
    final antes = transformacaoDaFoto(tester).getTranslation().x;

    final dedo = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    for (var i = 0; i < 15; i++) {
      await dedo.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // a medida é DURANTE o arrasto: solto, o PageView voltaria à página 0 de qualquer jeito
    expect(tester.widget<PageView>(find.byType(PageView)).controller?.page, 0);
    expect(transformacaoDaFoto(tester).getTranslation().x, lessThan(antes));
    await dedo.up();
    await tester.pumpAndSettle();
  });

  testWidgets('desfazer a pinça devolve o deslize entre fotos', (tester) async {
    await abrir(
      tester,
      registros: [
        registroDeTeste(id: 'r1', autor: eu),
        registroDeTeste(id: 'r2', autor: bia),
      ],
    );
    await pinca(tester, de: 30, ate: 174);
    await pinca(tester, de: 150, ate: 20);
    expect(transformacaoDaFoto(tester).getMaxScaleOnAxis(), closeTo(1, 0.01));

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets(
    'apagar a foto ampliada mostra a vizinha sem zoom e devolve o deslize',
    (tester) async {
      await abrir(
        tester,
        registros: [
          registroDeTeste(id: 'r1', autor: eu),
          registroDeTeste(id: 'r2', autor: bia),
          registroDeTeste(id: 'r3', autor: bia),
        ],
        podeApagar: (r) => r.id == 'r1',
        aoApagar: (_) async {},
      );
      await pinca(tester, de: 30, ate: 174);
      expect(transformacaoDaFoto(tester).getMaxScaleOnAxis(), greaterThan(1.5));

      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar').last);
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      expect(transformacaoDaFoto(tester).getMaxScaleOnAxis(), closeTo(1, 0.01));

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );
}
