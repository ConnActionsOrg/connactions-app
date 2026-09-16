import 'package:connactions_app/api/modelos/eu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Eu.deJson lê o contrato da API', () {
    final eu = Eu.deJson({
      'id': 'a1',
      'handle': 'marina.d',
      'nome': 'Marina Duarte',
      'foto_url': null,
      'bio': '',
      'codigo_de_amigo': 'ABCDEFGH',
      'atividades_visiveis': true,
      'criado_em': '2026-09-11T12:00:00-03:00',
    });
    expect(eu.handle, 'marina.d');
    expect(eu.fotoUrl, isNull);
    expect(eu.atividadesVisiveis, isTrue);
    expect(eu.criadoEm.toUtc(), DateTime.utc(2026, 9, 11, 15));
    expect(eu.copyWith(atividadesVisiveis: false).atividadesVisiveis, isFalse);

    final editado = eu.copyWith(
      nome: 'Marina D.',
      handle: 'marina.dd',
      bio: 'oi',
    );
    expect(editado.nome, 'Marina D.');
    expect(editado.handle, 'marina.dd');
    expect(editado.bio, 'oi');
    expect(editado.codigoDeAmigo, 'ABCDEFGH');
  });
}
