import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/design/cores.dart';
import 'package:connactions_app/design/widgets/disco_de_emoji.dart';
import 'package:connactions_app/features/diario/cartao_da_capa.dart';
import 'package:connactions_app/features/diario/paleta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

Widget capaEm(
  CapaDoDiario capa, {
  VoidCallback? aoPersonalizar,
  double escala = 1,
}) => montar(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(escala)),
      child: SingleChildScrollView(
        child: CartaoDaCapa(
          capa: capa,
          turma: turmaDeTeste(),
          aoPersonalizar: aoPersonalizar ?? () {},
        ),
      ),
    ),
  ),
);

Color? fundoDoCartao(WidgetTester tester) {
  final cartao = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(CartaoDaCapa),
          matching: find.byType(Container),
        )
        .first,
  );
  return (cartao.decoration as BoxDecoration).color;
}

void main() {
  testWidgets(
    'a capa padrão: título da turma, sem frase, sticker livro e contadores zerados',
    (tester) async {
      await tester.pumpWidget(capaEm(capaDeTeste()));

      expect(find.text('Diário de 🌿 Turma do Domingo'), findsOneWidget);
      expect(find.text('0 atividades'), findsOneWidget);
      expect(find.text('0 fotos'), findsOneWidget);
      expect(find.text('📖'), findsOneWidget);
      expect(find.byType(CartaoDaCapa), findsOneWidget);
      expect(find.byTooltip('Personalizar o diário'), findsOneWidget);
    },
  );

  testWidgets(
    'a capa personalizada mostra título, frase, sticker e contadores',
    (tester) async {
      await tester.pumpWidget(
        capaEm(
          capaDeTeste(
            titulo: 'Noites de quinta',
            frase: 'Quem não vem, perde a pizza.',
            sticker: StickerDoDiario.pizza,
            atividades: 12,
            fotos: 47,
          ),
        ),
      );

      expect(find.text('Noites de quinta'), findsOneWidget);
      expect(find.text('Quem não vem, perde a pizza.'), findsOneWidget);
      expect(find.text('🍕'), findsOneWidget);
      expect(find.text('12 atividades'), findsOneWidget);
      expect(find.text('47 fotos'), findsOneWidget);
      // com título próprio, o padrão não aparece
      expect(find.textContaining('Diário de'), findsNothing);
    },
  );

  testWidgets('um só item fica no singular', (tester) async {
    await tester.pumpWidget(capaEm(capaDeTeste(atividades: 1, fotos: 1)));

    expect(find.text('1 atividade'), findsOneWidget);
    expect(find.text('1 foto'), findsOneWidget);
  });

  testWidgets('cada paleta pinta o fundo da capa e o disco do sticker', (
    tester,
  ) async {
    for (final paleta in PaletaDoDiario.values) {
      await tester.pumpWidget(capaEm(capaDeTeste(paleta: paleta)));
      final esperado = coresDaPaleta(paleta, Cores.claras);

      expect(fundoDoCartao(tester), esperado.capa, reason: paleta.name);
      final disco = tester.widget<DiscoDeEmoji>(find.byType(DiscoDeEmoji));
      expect(disco.cor, esperado.disco, reason: paleta.name);
    }
  });

  testWidgets('tocar no lápis chama aoPersonalizar', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      capaEm(capaDeTeste(), aoPersonalizar: () => toques++),
    );

    await tester.tap(find.byTooltip('Personalizar o diário'));

    expect(toques, 1);
  });

  testWidgets(
    'título e frase no limite, com a fonte do Android no dobro, não estouram nem passam por baixo do sticker',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final titulo = 'T' * 40;
      final frase = 'f' * 80;
      await tester.pumpWidget(
        capaEm(
          capaDeTeste(titulo: titulo, frase: frase, atividades: 12, fotos: 47),
          escala: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      final sticker = tester.getRect(find.byType(DiscoDeEmoji));
      expect(
        tester.getRect(find.text(titulo)).right,
        lessThanOrEqualTo(sticker.left + 8),
      );
      expect(
        tester.getRect(find.text(frase)).right,
        lessThanOrEqualTo(sticker.left + 8),
      );
      // o lápis fica abaixo do contador, sem cobri-lo
      expect(
        tester.getRect(find.byTooltip('Personalizar o diário')).top,
        greaterThanOrEqualTo(tester.getRect(find.text('12 atividades')).bottom),
      );
    },
  );

  testWidgets('título curto e sem frase: o lápis fica abaixo do sticker', (
    tester,
  ) async {
    await tester.pumpWidget(capaEm(capaDeTeste(titulo: 'Quinta')));

    expect(
      tester.getRect(find.byTooltip('Personalizar o diário')).top,
      greaterThanOrEqualTo(tester.getRect(find.byType(DiscoDeEmoji)).bottom),
    );
  });
}
