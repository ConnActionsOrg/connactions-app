import 'package:connactions_app/features/perfil/codigo_de_amigo.dart';
import 'package:connactions_app/features/turmas/codigo_de_convite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o texto que vai pelo WhatsApp termina no código', () {
    expect(
      textoDoCodigoDeAmigo('BEAZ2345'),
      'Bora se conectar no ConnActions! No app, vá em Perfil › Conectar amigo e digite BEAZ2345.',
    );
  });

  test('colado inteiro no campo, vale o código escrito no fim', () {
    // "conectar" e "Conectar" têm oito letras, mas o O não é do alfabeto: só o código fecha
    final saida = FormatadorDeCodigo().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: textoDoCodigoDeAmigo('BEAZ2345')),
    );
    expect(saida.text, 'BEAZ2345');
    expect(saida.selection.baseOffset, 8);
  });
}
