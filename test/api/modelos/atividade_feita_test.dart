import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/atividade_feita.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> feitaJson({String id = 'a1', List<Object>? fotos}) => {
  'id': id,
  'titulo': 'Piquenique no parque',
  'formato': 'individual',
  'encerrada_em': '2026-10-15T22:10:05.123456Z',
  'turma': {'nome': 'Turma do Domingo', 'emoji': '🌿'},
  'fotos':
      fotos ??
      [
        {
          'foto_url': 'http://midia.local/midia/registros/a.jpg',
          'miniatura_url': 'http://midia.local/midia/registros/a.min.jpg',
          'legenda': 'Bolo de fubá',
        },
        {
          'foto_url': 'http://midia.local/midia/registros/b.jpg',
          'miniatura_url': 'http://midia.local/midia/registros/b.min.jpg',
          'legenda': '',
        },
      ],
};

void main() {
  test(
    'AtividadeFeita.deJson lê o formato, a data em UTC, a turma e as fotos na ordem',
    () {
      final a = AtividadeFeita.deJson(feitaJson());
      expect(a.id, 'a1');
      expect(a.titulo, 'Piquenique no parque');
      expect(a.formato, FormatoDeAtividade.individual);
      expect(a.encerradaEm, DateTime.utc(2026, 10, 15, 22, 10, 5, 123, 456));
      expect(a.encerradaEm.isUtc, isTrue);
      expect(a.turmaNome, 'Turma do Domingo');
      expect(a.turmaEmoji, '🌿');
      expect(a.fotos.map((f) => f.legenda), ['Bolo de fubá', '']);
      expect(a.fotos.first.fotoUrl, endsWith('registros/a.jpg'));
      expect(a.fotos.first.miniaturaUrl, endsWith('registros/a.min.jpg'));
    },
  );

  test('sem fotos, a lista vem vazia', () {
    final a = AtividadeFeita.deJson(feitaJson(fotos: const []));
    expect(a.fotos, isEmpty);
  });

  test('PaginaDeAtividadesFeitas.deJson com e sem próximo', () {
    final com = PaginaDeAtividadesFeitas.deJson({
      'itens': [feitaJson(id: 'a2'), feitaJson(id: 'a1')],
      'proximo': 'c2',
    });
    expect(com.itens.map((a) => a.id), ['a2', 'a1']);
    expect(com.proximo, 'c2');

    final sem = PaginaDeAtividadesFeitas.deJson({
      'itens': <Object>[],
      'proximo': null,
    });
    expect(sem.itens, isEmpty);
    expect(sem.proximo, isNull);
  });
}
