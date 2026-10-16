import 'package:connactions_app/api/modelos/foto_sem_autor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FotoSemAutor.deJson lê a foto, a miniatura e a legenda', () {
    final f = FotoSemAutor.deJson({
      'foto_url': 'http://midia.local/midia/registros/a.jpg',
      'miniatura_url': 'http://midia.local/midia/registros/a.min.jpg',
      'legenda': 'Vitória da Bia',
    });
    expect(f.fotoUrl, 'http://midia.local/midia/registros/a.jpg');
    expect(f.miniaturaUrl, 'http://midia.local/midia/registros/a.min.jpg');
    expect(f.legenda, 'Vitória da Bia');
  });
}
