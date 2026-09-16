import 'package:connactions_app/features/turmas/seletor_de_turma.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';

Future<void> abrirDiario(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Diário'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem turma, o vazio de sempre e nenhuma pílula', (tester) async {
    await abrirDiario(tester, FakeApi(eu: euDeTeste()));
    expect(find.text('O diário começa vazio'), findsOneWidget);
    expect(find.byType(SeletorDeTurma), findsNothing);
  });

  testWidgets('com turma, a pílula e o vazio daquela turma', (tester) async {
    await abrirDiario(
      tester,
      FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
    );
    expect(find.byType(SeletorDeTurma), findsOneWidget);
    expect(find.text('O diário da turma começa vazio'), findsOneWidget);
    expect(
      find.text(
        'As atividades encerradas de 🌿 Turma do Domingo vão aparecer aqui.',
      ),
      findsOneWidget,
    );
  });
}
