import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/api/modelos/pagina_da_comunidade.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> itemJson({List<Object>? fotos}) => {
  'id': 'a1',
  'titulo': 'Noite de jogos',
  'descricao': 'Cada um leva um jogo.',
  'regras': ['Um jogo por pessoa'],
  'formato': 'grupo',
  'encerrada_em': '2026-10-04T21:30:00Z',
  'turma': {'nome': 'Turma Prova', 'emoji': '🍕'},
  'fotos':
      fotos ??
      [
        {
          'foto_url': 'http://midia.local/midia/registros/a.jpg',
          'miniatura_url': 'http://midia.local/midia/registros/a.min.jpg',
          'legenda': 'Vitória da Bia',
        },
      ],
  'inspiradas': 3,
};

void main() {
  test('AtividadeDaComunidade.deJson lê a turma, as fotos e a contagem', () {
    final a = AtividadeDaComunidade.deJson(itemJson());
    expect(a.id, 'a1');
    expect(a.titulo, 'Noite de jogos');
    expect(a.descricao, 'Cada um leva um jogo.');
    expect(a.regras, ['Um jogo por pessoa']);
    expect(a.formato, FormatoDeAtividade.grupo);
    expect(a.encerradaEm, DateTime.utc(2026, 10, 4, 21, 30));
    expect(a.turmaNome, 'Turma Prova');
    expect(a.turmaEmoji, '🍕');
    expect(a.inspiradas, 3);
    expect(a.fotos.single.legenda, 'Vitória da Bia');
    expect(a.fotos.single.fotoUrl, endsWith('registros/a.jpg'));
    expect(a.fotos.single.miniaturaUrl, endsWith('registros/a.min.jpg'));
  });

  test('PaginaDaComunidade.deJson com e sem próximo', () {
    final com = PaginaDaComunidade.deJson({
      'itens': [itemJson()],
      'proximo': 'c2',
    });
    expect(com.itens.single.id, 'a1');
    expect(com.proximo, 'c2');

    final sem = PaginaDaComunidade.deJson({
      'itens': <Object>[],
      'proximo': null,
    });
    expect(sem.itens, isEmpty);
    expect(sem.proximo, isNull);
  });
}
