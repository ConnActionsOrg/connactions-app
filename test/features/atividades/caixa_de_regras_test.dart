import 'package:connactions_app/features/atividades/cartao_da_atividade.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/montar.dart';

void main() {
  testWidgets('uma linha com marcador por regra', (tester) async {
    await tester.pumpWidget(
      montar(
        const CaixaDeRegras(regras: ['Um item por pessoa', 'Foto ao ar livre']),
      ),
    );

    expect(find.text('Um item por pessoa'), findsOneWidget);
    expect(find.text('Foto ao ar livre'), findsOneWidget);
    expect(find.text('•  '), findsNWidgets(2));
  });
}
