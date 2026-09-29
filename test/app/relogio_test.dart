import 'package:connactions_app/app/relogio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o padrão é o relógio de verdade', () {
    final c = ProviderContainer.test();
    final antes = DateTime.now();
    final agora = c.read(relogioProvider)();
    expect(agora.difference(antes).inSeconds, lessThan(2));
  });

  test('sobrescrito, congela', () {
    final fixo = DateTime.utc(2026, 9, 29, 12);
    final c = ProviderContainer.test(
      overrides: [relogioProvider.overrideWithValue(() => fixo)],
    );
    expect(c.read(relogioProvider)(), fixo);
  });
}
