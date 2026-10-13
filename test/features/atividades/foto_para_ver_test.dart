import 'package:connactions_app/features/atividades/foto_para_ver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';

void main() {
  test('doRegistro leva id, autor e quando foi postado', () {
    final registro = registroDeTeste(id: 'r1', legenda: 'Bolo');

    final foto = FotoParaVer.doRegistro(registro);

    expect(foto.id, 'r1');
    expect(foto.url, registro.fotoUrl);
    expect(foto.legenda, 'Bolo');
    expect(foto.autor?.id, registro.autor.id);
    expect(foto.postadaEm, registro.criadoEm);
  });

  test('daComunidade só tem url e legenda', () {
    final comunidade = fotoDaComunidadeDeTeste(legenda: 'Vitória da Bia');

    final foto = FotoParaVer.daComunidade(comunidade);

    expect(foto.url, comunidade.fotoUrl);
    expect(foto.legenda, 'Vitória da Bia');
    expect(foto.id, isNull);
    expect(foto.autor, isNull);
    expect(foto.postadaEm, isNull);
  });
}
