import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';

Map<String, dynamic> capaJson({
  Object? titulo,
  Object? frase,
  String paleta = 'areia',
  String sticker = 'livro',
}) => {
  'titulo': titulo,
  'frase': frase,
  'paleta': paleta,
  'sticker': sticker,
  'atividades': 12,
  'fotos': 47,
};

void main() {
  test('as paletas e os stickers têm as listas fechadas da API', () {
    expect(PaletaDoDiario.values.map((p) => p.name), [
      'terracota',
      'ambar',
      'salvia',
      'areia',
    ]);
    expect(StickerDoDiario.values.map((s) => s.name), [
      'livro',
      'pizza',
      'planta',
      'cafe',
      'cinema',
      'praia',
      'jogo',
      'musica',
      'estrela',
      'comida',
    ]);
    expect(PaletaDoDiario.padrao, PaletaDoDiario.areia);
    expect(StickerDoDiario.padrao, StickerDoDiario.livro);
  });

  test('CapaDoDiario.deJson lê a capa personalizada e os contadores', () {
    final c = CapaDoDiario.deJson(
      capaJson(
        titulo: 'Noites de quinta',
        frase: 'Quem não vem, perde a pizza.',
        paleta: 'terracota',
        sticker: 'pizza',
      ),
    );
    expect(c.titulo, 'Noites de quinta');
    expect(c.frase, 'Quem não vem, perde a pizza.');
    expect(c.paleta, PaletaDoDiario.terracota);
    expect(c.sticker, StickerDoDiario.pizza);
    expect(c.atividades, 12);
    expect(c.fotos, 47);
  });

  test('a capa nova tem título e frase nulos, e o título cai no padrão', () {
    final c = CapaDoDiario.deJson(capaJson());
    expect(c.titulo, isNull);
    expect(c.frase, isNull);
    expect(c.tituloPara(turmaDeTeste()), 'Diário de 🌿 Turma do Domingo');
    expect(
      CapaDoDiario.deJson(
        capaJson(titulo: 'Meu diário'),
      ).tituloPara(turmaDeTeste()),
      'Meu diário',
    );
  });

  test(
    'paleta e sticker que o app não conhece viram o padrão, sem estourar',
    () {
      final c = CapaDoDiario.deJson(
        capaJson(paleta: 'neon', sticker: 'foguete'),
      );
      expect(c.paleta, PaletaDoDiario.areia);
      expect(c.sticker, StickerDoDiario.livro);
    },
  );

  test('AlteracoesDaCapa manda só o que mudou, pelo slug', () {
    expect(const AlteracoesDaCapa().vazia, isTrue);
    expect(const AlteracoesDaCapa().toJson(), isEmpty);

    const tudo = AlteracoesDaCapa(
      titulo: 'Noites de quinta',
      frase: '',
      paleta: PaletaDoDiario.ambar,
      sticker: StickerDoDiario.cafe,
    );
    expect(tudo.vazia, isFalse);
    expect(tudo.toJson(), {
      'titulo': 'Noites de quinta',
      'frase': '', // vazio = voltar ao padrão
      'paleta': 'ambar',
      'sticker': 'cafe',
    });
    expect(const AlteracoesDaCapa(sticker: StickerDoDiario.praia).toJson(), {
      'sticker': 'praia',
    });
  });
}
