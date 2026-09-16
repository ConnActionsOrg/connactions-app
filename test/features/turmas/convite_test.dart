import 'package:connactions_app/features/turmas/convite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';

void main() {
  test('o convite leva emoji, nome e o código, e diz onde digitar', () {
    final texto = textoDoConvite(
      turmaDeTeste(
        nome: 'Turma do Domingo',
        emoji: '🌿',
        codigoConvite: 'ABCD2345',
      ),
    );
    expect(
      texto,
      'Vem pra turma 🌿 Turma do Domingo no ConnActions! '
      'Abra o app, toque em Entrar com código e digite ABCD2345.',
    );
  });
}
