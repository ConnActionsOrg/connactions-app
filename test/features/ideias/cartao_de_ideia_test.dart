import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/features/ideias/cartao_de_ideia.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

void main() {
  testWidgets('minha ideia digitada: título, descrição e "Sua ideia"', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(
        CartaoDeIdeia(
          ideia: ideiaDeTeste(titulo: 'Pizza', descricao: 'Com forno'),
          souEu: true,
        ),
      ),
    );

    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Com forno'), findsOneWidget);
    expect(find.text('Sua ideia'), findsOneWidget);
    expect(find.text('Da Comunidade'), findsNothing);
    expect(find.text('Apagar'), findsNothing);
    expect(find.text('Propor esta'), findsNothing);
  });

  testWidgets('ideia alheia da Comunidade: autor, origem e formato', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(
        CartaoDeIdeia(
          ideia: ideiaDeTeste(
            autor: pessoaDeTeste(nome: 'Carol Souza'),
            origemAtividadeId: 'com-1',
            formato: FormatoDeAtividade.grupo,
          ),
          souEu: false,
        ),
      ),
    );

    expect(find.text('Sugerido por Carol'), findsOneWidget);
    expect(find.text('Da Comunidade'), findsOneWidget);
    expect(find.text('Em grupo'), findsOneWidget);
  });

  testWidgets('as ações aparecem com o callback e o chamam', (tester) async {
    var apagou = 0;
    var propos = 0;
    await tester.pumpWidget(
      montar(
        CartaoDeIdeia(
          ideia: ideiaDeTeste(),
          souEu: true,
          aoApagar: () => apagou++,
          aoProporEsta: () => propos++,
        ),
      ),
    );

    await tester.tap(find.text('Apagar'));
    await tester.tap(find.text('Propor esta'));

    expect(apagou, 1);
    expect(propos, 1);
  });
}
