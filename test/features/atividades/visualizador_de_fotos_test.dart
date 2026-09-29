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
}
