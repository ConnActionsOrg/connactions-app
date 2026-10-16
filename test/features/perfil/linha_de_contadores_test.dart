import 'package:connactions_app/api/modelos/perfil_de_pessoa.dart';
import 'package:connactions_app/features/perfil/linha_de_contadores.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

PerfilDePessoa perfilCom({
  required int turmas,
  required int? atividades,
  required int conexoes,
}) => PerfilDePessoa(
  id: 'pessoa-bia',
  handle: 'bia',
  nome: 'Bia Souza',
  fotoUrl: null,
  bio: '',
  turmas: turmas,
  atividades: atividades,
  conexoes: conexoes,
);

/// Com as margens do Perfil (a da tela e a do cartão de identidade) e a fonte na [escala] dada.
Widget linhaEm(LinhaDeContadores linha, {double escala = 1}) => montar(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(escala)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: linha,
      ),
    ),
  ),
);

void main() {
  testWidgets('os três contadores, cada um com o número e o rótulo', (
    tester,
  ) async {
    await tester.pumpWidget(
      linhaEm(
        LinhaDeContadores(
          perfil: perfilCom(turmas: 4, atividades: 23, conexoes: 18),
        ),
      ),
    );

    for (final texto in ['4', 'Turmas', '23', 'Atividades', '18', 'Conexões']) {
      expect(find.text(texto), findsOneWidget, reason: texto);
    }
  });

  testWidgets('com 1, o rótulo vai no singular', (tester) async {
    await tester.pumpWidget(
      linhaEm(
        LinhaDeContadores(
          perfil: perfilCom(turmas: 1, atividades: 1, conexoes: 1),
        ),
      ),
    );

    expect(find.text('Turma'), findsOneWidget);
    expect(find.text('Atividade'), findsOneWidget);
    expect(find.text('Conexão'), findsOneWidget);
    expect(find.text('Turmas'), findsNothing);
  });

  testWidgets('sem o de atividades quando ele vem nulo', (tester) async {
    await tester.pumpWidget(
      linhaEm(
        LinhaDeContadores(
          perfil: perfilCom(turmas: 4, atividades: null, conexoes: 18),
        ),
      ),
    );

    expect(find.text('Turmas'), findsOneWidget);
    expect(find.text('Conexões'), findsOneWidget);
    expect(find.textContaining('Atividade'), findsNothing);
  });

  testWidgets('carregando, os números viram "–" e os rótulos ficam', (
    tester,
  ) async {
    await tester.pumpWidget(linhaEm(const LinhaDeContadores.carregando()));

    expect(find.text('–'), findsNWidgets(3));
    expect(find.text('Turmas'), findsOneWidget);
    expect(find.text('Atividades'), findsOneWidget);
    expect(find.text('Conexões'), findsOneWidget);
  });

  testWidgets(
    'com três dígitos, 360 px e a fonte do Android no dobro, nada estoura e nenhum rótulo some',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        linhaEm(
          LinhaDeContadores(
            perfil: perfilCom(turmas: 999, atividades: 888, conexoes: 777),
          ),
          escala: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      final linha = tester.getRect(find.byType(LinhaDeContadores));
      for (final texto in [
        '999',
        'Turmas',
        '888',
        'Atividades',
        '777',
        'Conexões',
      ]) {
        final caixa = tester.getRect(find.text(texto));
        expect(caixa.width, greaterThan(0), reason: texto);
        expect(linha.contains(caixa.topLeft), isTrue, reason: texto);
        expect(
          linha.contains(caixa.bottomRight - const Offset(1, 1)),
          isTrue,
          reason: texto,
        );
        // inteiro, sem as reticências de quem corta para caber
        final paragrafo = tester.renderObject<RenderParagraph>(
          find.text(texto),
        );
        expect(paragrafo.didExceedMaxLines, isFalse, reason: texto);
      }
    },
  );
}
