import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/atividade_feita.dart';
import 'package:connactions_app/design/widgets/avatar.dart';
import 'package:connactions_app/design/widgets/etiqueta.dart';
import 'package:connactions_app/features/atividades/visualizador_de_fotos.dart';
import 'package:connactions_app/features/perfil/cartao_de_atividade_feita.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

final agora = DateTime.utc(2026, 10, 20, 12);

Future<void> montarCartao(WidgetTester tester, AtividadeFeita atividade) =>
    tester.pumpWidget(
      montar(
        SingleChildScrollView(
          child: CartaoDeAtividadeFeita(atividade: atividade, agora: agora),
        ),
      ),
    );

/// A foto grande, pelo nome acessível do toque.
Finder foto(String rotulo) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == rotulo,
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('o título, a turma com o emoji, a data do Diário e o formato', (
    tester,
  ) async {
    // 01:00 UTC ainda é o dia anterior onde o fuso é negativo (Brasil); em UTC os dois coincidem
    final encerradaEm = DateTime.utc(2026, 10, 16, 1);
    await montarCartao(
      tester,
      atividadeFeitaDeTeste(
        titulo: 'Piquenique no parque',
        formato: FormatoDeAtividade.individual,
        encerradaEm: encerradaEm,
      ),
    );

    expect(find.text('Piquenique no parque'), findsOneWidget);
    final data = DateFormat(
      "d 'de' MMMM",
      'pt_BR',
    ).format(encerradaEm.toLocal());
    expect(find.text('🌿 Turma do Domingo · $data'), findsOneWidget);
    final etiqueta = tester.widget<Etiqueta>(find.byType(Etiqueta));
    expect(etiqueta.texto, 'Individual');
    expect(etiqueta.tom, TomDaEtiqueta.salvia);
  });

  testWidgets(
    'a primeira foto grande, o +N das outras e a legenda dela em itálico',
    (tester) async {
      await montarCartao(
        tester,
        atividadeFeitaDeTeste(
          fotos: [
            fotoSemAutorDeTeste(id: 'a', legenda: 'Bolo de fubá'),
            fotoSemAutorDeTeste(id: 'b', legenda: 'Outra'),
            fotoSemAutorDeTeste(id: 'c', legenda: ''),
          ],
        ),
      );

      final imagem = tester.widget<Image>(find.byType(Image));
      expect(
        (imagem.image as NetworkImage).url,
        'http://midia.local/midia/registros/a.jpg',
      );
      expect(find.text('+2'), findsOneWidget);
      final legenda = tester.widget<Text>(find.text('Bolo de fubá'));
      expect(legenda.style?.fontStyle, FontStyle.italic);
      expect(find.text('Outra'), findsNothing);
    },
  );

  testWidgets('com uma foto só e sem legenda, nem o +N nem o itálico', (
    tester,
  ) async {
    await montarCartao(
      tester,
      atividadeFeitaDeTeste(fotos: [fotoSemAutorDeTeste(legenda: '')]),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.style?.fontStyle == FontStyle.italic,
      ),
      findsNothing,
    );
  });

  testWidgets('tocar na foto abre o visualizador com todas, sem autor', (
    tester,
  ) async {
    await montarCartao(
      tester,
      atividadeFeitaDeTeste(
        fotos: [
          fotoSemAutorDeTeste(id: 'a', legenda: 'Bolo de fubá'),
          fotoSemAutorDeTeste(id: 'b', legenda: 'Outra'),
          fotoSemAutorDeTeste(id: 'c', legenda: 'Mais uma'),
        ],
      ),
    );

    await tester.tap(foto('Ver as 3 fotos'));
    await tester.pumpAndSettle();

    expect(find.byType(VisualizadorDeFotos), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Bolo de fubá'), findsOneWidget);
    expect(find.byType(Avatar), findsNothing);
    expect(find.byTooltip('Apagar'), findsNothing);
  });

  testWidgets('sem foto, só o texto', (tester) async {
    await montarCartao(tester, atividadeFeitaDeTeste(fotos: const []));

    expect(find.text('Noite de jogos'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label ?? '').startsWith('Ver '),
      ),
      findsNothing,
    );
  });

  testWidgets('a foto que não carrega vira um fundo neutro, sem exceção', (
    tester,
  ) async {
    await montarCartao(tester, atividadeFeitaDeTeste());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Symbols.image), findsOneWidget);
    expect(foto('Ver a foto'), findsOneWidget);
  });
}
