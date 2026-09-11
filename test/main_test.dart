import 'package:connactions_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('o app do template abre', (tester) async {
    await tester.pumpWidget(const MainApp());
    expect(find.text('Hello World!'), findsOneWidget);
  });
}
