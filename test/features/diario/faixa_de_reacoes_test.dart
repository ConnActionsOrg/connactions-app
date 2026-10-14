import 'dart:ui' show Tristate;

import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/api/modelos/reacao.dart';
import 'package:connactions_app/design/cores.dart';
import 'package:connactions_app/features/diario/faixa_de_reacoes.dart';
import 'package:connactions_app/features/diario/folha_de_reacoes.dart';
import 'package:connactions_app/features/diario/paleta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

const coracao2Meu = Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true);
const fogo1 = Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false);

Widget faixa({
  List<Reacao> reacoes = const [],
  int comentarios = 0,
  PaletaDoDiario paleta = PaletaDoDiario.areia,
  ValueChanged<TipoDeReacao>? aoReagir,
  VoidCallback? aoAbrirComentarios,
}) => montar(
  Padding(
    padding: const EdgeInsets.all(16),
    child: FaixaDeReacoes(
      reacoes: reacoes,
      totalDeComentarios: comentarios,
      paleta: paleta,
      aoReagir: aoReagir ?? (_) {},
      aoAbrirComentarios: aoAbrirComentarios ?? () {},
    ),
  ),
);

Color? fundoDoChip(WidgetTester tester, String rotulo) {
  final pilula = tester.widget<Ink>(
    find.descendant(of: find.byTooltip(rotulo), matching: find.byType(Ink)),
  );
  return (pilula.decoration as BoxDecoration).color;
}

void main() {
  testWidgets(
    'um chip por reação, com glifo e total; o "＋" e o balão sempre estão',
    (tester) async {
      await tester.pumpWidget(
        faixa(reacoes: [coracao2Meu, fogo1], comentarios: 3),
      );

      expect(find.text('❤️ 2'), findsOneWidget);
      expect(find.text('🔥 1'), findsOneWidget);
      expect(find.byTooltip('Reagir'), findsOneWidget);
      expect(find.byTooltip('3 comentários'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    },
  );

  testWidgets('sem reações, só o "＋" e o botão de comentar', (tester) async {
    await tester.pumpWidget(faixa());

    expect(find.byTooltip('Reagir'), findsOneWidget);
    expect(find.byTooltip('Comentar'), findsOneWidget);
    expect(find.textContaining('❤️'), findsNothing);
  });

  testWidgets(
    'os rótulos dizem o tipo, a conta no singular ou plural e se é minha',
    (tester) async {
      await tester.pumpWidget(
        faixa(
          reacoes: const [
            coracao2Meu,
            fogo1,
            Reacao(tipo: TipoDeReacao.festa, total: 5, minha: false),
          ],
          comentarios: 1,
        ),
      );

      expect(find.byTooltip('Coração, 2 reações, marcada'), findsOneWidget);
      expect(find.byTooltip('Fogo, 1 reação'), findsOneWidget);
      expect(find.byTooltip('Festa, 5 reações'), findsOneWidget);
      expect(find.byTooltip('1 comentário'), findsOneWidget);
    },
  );

  testWidgets(
    'o leitor de tela anuncia o chip uma vez, com o estado em selected',
    (tester) async {
      final semantica = tester.ensureSemantics();
      try {
        await tester.pumpWidget(faixa(reacoes: [coracao2Meu]));

        final achados = find.bySemanticsLabel(RegExp('Coração'));
        expect(achados, findsOneWidget);
        final no = tester.getSemantics(achados);
        expect(no.label, 'Coração, 2 reações');
        expect(no.flagsCollection.isSelected, Tristate.isTrue);
      } finally {
        semantica
            .dispose(); // síncrono: o teste verifica os handles ao terminar
      }
    },
  );

  testWidgets(
    'o chip que eu marquei usa as cores da paleta; o dos outros, o fundo comum',
    (tester) async {
      for (final paleta in PaletaDoDiario.values) {
        await tester.pumpWidget(
          faixa(reacoes: [coracao2Meu, fogo1], paleta: paleta),
        );
        final pintura = coresDaPaleta(paleta, Cores.claras);

        expect(
          fundoDoChip(tester, 'Coração, 2 reações, marcada'),
          pintura.chipFundo,
          reason: paleta.name,
        );
        expect(
          fundoDoChip(tester, 'Fogo, 1 reação'),
          Cores.claras.superficieMaisBaixa,
          reason: paleta.name,
        );
      }
    },
  );

  testWidgets('tocar num chip chama aoReagir com o tipo dele', (tester) async {
    final tipos = <TipoDeReacao>[];
    await tester.pumpWidget(
      faixa(reacoes: [coracao2Meu, fogo1], aoReagir: tipos.add),
    );

    await tester.tap(find.text('🔥 1'));
    await tester.tap(find.text('❤️ 2'));

    expect(tipos, [TipoDeReacao.fogo, TipoDeReacao.coracao]);
  });

  testWidgets('o "＋" abre os seis tipos; escolher um fecha a folha e reage', (
    tester,
  ) async {
    final tipos = <TipoDeReacao>[];
    await tester.pumpWidget(faixa(reacoes: [coracao2Meu], aoReagir: tipos.add));

    await tester.tap(find.byTooltip('Reagir'));
    await tester.pumpAndSettle();

    expect(find.byType(FolhaDeReacoes), findsOneWidget);
    for (final tipo in TipoDeReacao.values) {
      expect(find.text(tipo.glifo), findsWidgets, reason: tipo.slug);
    }
    // o que eu já marquei aparece marcado, para eu saber que tocar de novo desmarca
    expect(find.byTooltip('Coração, marcada'), findsOneWidget);
    expect(find.byTooltip('Fogo'), findsOneWidget);

    await tester.tap(find.byTooltip('Fogo'));
    await tester.pumpAndSettle();

    expect(tipos, [TipoDeReacao.fogo]);
    expect(find.byType(FolhaDeReacoes), findsNothing);
  });

  testWidgets('o botão de comentários chama aoAbrirComentarios', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(faixa(aoAbrirComentarios: () => toques++));

    await tester.tap(find.byTooltip('Comentar'));

    expect(toques, 1);
  });

  testWidgets('todos os alvos de toque têm ao menos 48 dp', (tester) async {
    await tester.pumpWidget(
      faixa(reacoes: [coracao2Meu, fogo1], comentarios: 2),
    );

    for (final rotulo in [
      'Coração, 2 reações, marcada',
      'Fogo, 1 reação',
      'Reagir',
      '2 comentários',
    ]) {
      final tamanho = tester.getSize(find.byTooltip(rotulo));
      expect(tamanho.height, greaterThanOrEqualTo(48), reason: rotulo);
      expect(tamanho.width, greaterThanOrEqualTo(48), reason: rotulo);
    }
  });

  testWidgets(
    'seis chips grandes numa tela estreita quebram de linha sem estourar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        faixa(
          reacoes: [
            for (final tipo in TipoDeReacao.values)
              Reacao(tipo: tipo, total: 99, minha: true),
          ],
          comentarios: 120,
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}
