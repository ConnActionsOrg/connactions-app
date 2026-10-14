import 'package:connactions_app/api/modelos/reacao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('os seis tipos têm slug, glifo e rótulo, e o slug nunca é o emoji', () {
    expect(TipoDeReacao.values.map((t) => t.slug), [
      'coracao',
      'risada',
      'apaixonado',
      'palmas',
      'fogo',
      'festa',
    ]);
    expect(TipoDeReacao.values.map((t) => t.glifo), [
      '❤️',
      '😂',
      '😍',
      '👏',
      '🔥',
      '🥳',
    ]);
    for (final tipo in TipoDeReacao.values) {
      expect(tipo.slug, matches(RegExp(r'^[a-z]+$')), reason: tipo.slug);
      expect(tipo.rotulo, isNotEmpty);
    }
  });

  test('doSlug acha pelo slug e devolve nulo para o que não conhece', () {
    expect(TipoDeReacao.doSlug('fogo'), TipoDeReacao.fogo);
    expect(TipoDeReacao.doSlug('FOGO'), isNull);
    expect(TipoDeReacao.doSlug('❤️'), isNull);
    expect(TipoDeReacao.doSlug(''), isNull);
  });

  test('Reacao.deJson lê o resumo', () {
    final r = Reacao.deJson(const {
      'tipo': 'coracao',
      'total': 2,
      'minha': true,
    });
    expect(r, const Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true));
  });

  test('um tipo desconhecido é descartado, e o resto da lista segue', () {
    final lista = Reacao.listaDeJson(const [
      {'tipo': 'coracao', 'total': 2, 'minha': true},
      {'tipo': 'unicornio', 'total': 9, 'minha': false},
      {'tipo': 'fogo', 'total': 1, 'minha': false},
    ]);
    expect(lista, const [
      Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true),
      Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false),
    ]);
  });

  test('a igualdade compara os três campos', () {
    const base = Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false);
    expect(base, const Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false));
    expect(
      base == const Reacao(tipo: TipoDeReacao.fogo, total: 2, minha: false),
      isFalse,
    );
    expect(
      base == const Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: true),
      isFalse,
    );
    expect(
      base == const Reacao(tipo: TipoDeReacao.festa, total: 1, minha: false),
      isFalse,
    );
  });
}
