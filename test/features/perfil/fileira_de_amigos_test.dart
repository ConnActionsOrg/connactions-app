import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/features/perfil/fileira_de_amigos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

const caio = Pessoa(
  id: 'pessoa-caio',
  handle: 'caio',
  nome: 'Caio Lima',
  fotoUrl: null,
);

/// Com a margem do Perfil e a fonte na [escala] dada.
Widget fileiraEm(FileiraDeAmigos fileira, {double escala = 1}) => montar(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(escala)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: fileira,
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'o "Conectar amigo" primeiro e depois os amigos, com o primeiro nome e o @handle',
    (tester) async {
      await tester.pumpWidget(
        fileiraEm(FileiraDeAmigos(amigos: [pessoaDeTeste(), caio])),
      );

      expect(find.text('pelo código'), findsOneWidget);
      expect(find.text('@bia'), findsOneWidget);
      expect(find.text('@caio'), findsOneWidget);
      final conectar = tester.getTopLeft(find.text('Conectar amigo')).dx;
      final bia = tester.getTopLeft(find.text('Bia')).dx;
      final caioX = tester.getTopLeft(find.text('Caio')).dx;
      expect(conectar, lessThan(bia));
      expect(bia, lessThan(caioX));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'carregando: o cartão de conectar e o indicador no lugar dos amigos',
    (tester) async {
      await tester.pumpWidget(
        fileiraEm(const FileiraDeAmigos(amigos: [], carregando: true)),
      );

      expect(find.text('Conectar amigo'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'nome e @handle longos, a 360 px e com a fonte no dobro: nada estoura e o texto corta com reticências',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final longa = pessoaDeTeste(
        id: 'pessoa-longa',
        nome: 'Bartholomeu-Maximiliano-Augusto Pereira',
        handle: 'bartholomeu.maximiliano.augusto',
      );

      await tester.pumpWidget(
        fileiraEm(FileiraDeAmigos(amigos: [longa, caio]), escala: 2),
      );

      expect(tester.takeException(), isNull);
      for (final texto in [
        'Bartholomeu-Maximiliano-Augusto',
        '@bartholomeu.maximiliano.augusto',
      ]) {
        final paragrafo = tester.renderObject<RenderParagraph>(
          find.text(texto),
        );
        expect(paragrafo.didExceedMaxLines, isTrue, reason: texto);
        expect(paragrafo.overflow, TextOverflow.ellipsis, reason: texto);
      }
      // e o cartão de conectar continua lá, inteiro na altura da fileira
      expect(find.text('Conectar amigo'), findsOneWidget);
    },
  );
}
