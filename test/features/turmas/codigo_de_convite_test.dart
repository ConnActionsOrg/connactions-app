import 'package:connactions_app/features/turmas/codigo_de_convite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizar tira espaços e sobe para maiúsculas', () {
    expect(normalizarCodigo(' abcd 2345 '), 'ABCD2345');
  });

  test('completo exige oito caracteres do alfabeto', () {
    expect(codigoCompleto('ABCD2345'), isTrue);
    expect(codigoCompleto('ABCD234'), isFalse);
    expect(
      codigoCompleto('ABCD234O'),
      isFalse,
      reason: 'a letra O não existe no alfabeto',
    );
    expect(
      codigoCompleto('abcd2345'),
      isFalse,
      reason: 'minúsculas só depois de normalizar',
    );
  });

  test('o formatador limpa o que a pessoa digita ou cola', () {
    final saida = FormatadorDeCodigo().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'ab cd-23 45 xyz0'),
    );
    // "-" e "0" não pertencem ao alfabeto; "XYZ" passa dos oito
    expect(saida.text, 'ABCD2345');
    expect(saida.selection.baseOffset, 8);
  });
}
