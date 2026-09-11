import 'package:connactions_app/design/widgets/estado_de_erro.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

void main() {
  testWidgets('mostra a mensagem e o botão chama a ação', (tester) async {
    var tentou = false;
    await tester.pumpWidget(
      montar(
        EstadoDeErro(
          mensagem: 'Sem conexão com a API.',
          aoTentarDeNovo: () => tentou = true,
        ),
      ),
    );

    expect(find.text('Sem conexão com a API.'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    expect(tentou, isTrue);
  });
}
