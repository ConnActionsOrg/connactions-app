import 'package:connactions_app/api/modelos/comentario.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> comentarioJson({String id = 'c1', bool meu = false}) => {
  'id': id,
  'autor': {
    'id': 'p1',
    'handle': 'bia.souza',
    'nome': 'Bia Souza',
    'foto_url': null,
  },
  'texto': 'Foi demais!',
  'criado_em': '2026-10-14T15:01:51.697777Z',
  'meu': meu,
};

void main() {
  test('Comentario.deJson lê o autor, o texto, a data em UTC e o "meu"', () {
    final c = Comentario.deJson(comentarioJson(meu: true));
    expect(c.id, 'c1');
    expect(c.autor.nome, 'Bia Souza');
    expect(c.autor.primeiroNome, 'Bia');
    expect(c.texto, 'Foi demais!');
    expect(c.criadoEm, DateTime.utc(2026, 10, 14, 15, 1, 51, 697, 777));
    expect(c.meu, isTrue);
  });

  test('PaginaDeComentarios.deJson lê os itens e o cursor, nulo no fim', () {
    final p = PaginaDeComentarios.deJson({
      'itens': [comentarioJson(id: 'c1'), comentarioJson(id: 'c2')],
      'proximo': 'abc',
    });
    expect(p.itens.map((c) => c.id), ['c1', 'c2']);
    expect(p.proximo, 'abc');

    final fim = PaginaDeComentarios.deJson({
      'itens': <Object>[],
      'proximo': null,
    });
    expect(fim.itens, isEmpty);
    expect(fim.proximo, isNull);
  });
}
