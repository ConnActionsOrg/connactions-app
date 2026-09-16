import 'package:connactions_app/api/modelos/alteracoes_do_eu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson leva só o que mudou', () {
    expect(const AlteracoesDoEu(nome: 'Marina D.').toJson(), {
      'nome': 'Marina D.',
    });
    expect(const AlteracoesDoEu(bio: '', atividadesVisiveis: false).toJson(), {
      'bio': '',
      'atividades_visiveis': false,
    });
    expect(const AlteracoesDoEu(handle: 'marina.d').toJson(), {
      'handle': 'marina.d',
    });
  });

  test('vazia quando nada mudou', () {
    expect(const AlteracoesDoEu().vazia, isTrue);
    expect(const AlteracoesDoEu(handle: 'x').vazia, isFalse);
  });
}
