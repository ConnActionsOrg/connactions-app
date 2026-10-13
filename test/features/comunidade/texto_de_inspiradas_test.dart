import 'package:connactions_app/features/comunidade/texto_de_inspiradas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nada para zero, singular para um e plural para o resto', () {
    expect(textoDeInspiradas(0), isNull);
    expect(textoDeInspiradas(1), '1 turma se inspirou');
    expect(textoDeInspiradas(2), '2 turmas se inspiraram');
    expect(textoDeInspiradas(11), '11 turmas se inspiraram');
  });
}
