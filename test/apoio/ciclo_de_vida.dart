import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// O app vai para o fundo e volta, como quem passou pelas configurações do Android. Pela mensagem
/// de plataforma, que gera as transições intermediárias que o AppLifecycleListener exige.
Future<void> sairEVoltarAoApp(WidgetTester tester) async {
  for (final estado in [AppLifecycleState.paused, AppLifecycleState.resumed]) {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StringCodec().encodeMessage(estado.toString()),
      (_) {},
    );
  }
  await tester.pumpAndSettle();
}
