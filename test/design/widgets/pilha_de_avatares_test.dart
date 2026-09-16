import 'package:connactions_app/design/widgets/avatar.dart';
import 'package:connactions_app/design/widgets/pilha_de_avatares.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

void main() {
  testWidgets('mostra até quatro e resume o resto em +N', (tester) async {
    final pessoas = [
      for (var i = 0; i < 6; i++)
        pessoaDeTeste(id: 'p$i', handle: 'p$i', nome: 'Pessoa $i'),
    ];
    await tester.pumpWidget(montar(PilhaDeAvatares(pessoas: pessoas)));

    expect(find.byType(Avatar), findsNWidgets(4));
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('com poucas pessoas não há +N', (tester) async {
    await tester.pumpWidget(
      montar(
        PilhaDeAvatares(
          pessoas: [
            pessoaDeTeste(),
            pessoaDeTeste(id: 'x'),
          ],
        ),
      ),
    );
    expect(find.byType(Avatar), findsNWidgets(2));
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('sem pessoas não desenha nada', (tester) async {
    await tester.pumpWidget(montar(const PilhaDeAvatares(pessoas: [])));
    expect(find.byType(Avatar), findsNothing);
  });
}
