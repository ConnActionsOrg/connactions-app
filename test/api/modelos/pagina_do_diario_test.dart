import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/api/modelos/pagina_do_diario.dart';
import 'package:connactions_app/api/modelos/reacao.dart';
import 'package:flutter_test/flutter_test.dart';

import 'atividade_test.dart' show atividadeJson;

Map<String, dynamic> itemJson({
  String id = 'a1',
  List<Object> reacoes = const [],
  int comentarios = 0,
}) => {
  ...atividadeJson(encerradaEm: '2026-09-30T10:00:00Z'),
  'id': id,
  'reacoes': reacoes,
  'total_de_comentarios': comentarios,
};

const capaJson = {
  'titulo': null,
  'frase': null,
  'paleta': 'areia',
  'sticker': 'livro',
  'atividades': 2,
  'fotos': 0,
};

void main() {
  test(
    'ItemDoDiario.deJson lê a atividade, as reações e o total de comentários',
    () {
      final item = ItemDoDiario.deJson(
        itemJson(
          reacoes: const [
            {'tipo': 'coracao', 'total': 2, 'minha': true},
            {'tipo': 'fogo', 'total': 1, 'minha': false},
          ],
          comentarios: 3,
        ),
      );
      expect(item.atividade.id, 'a1');
      expect(item.atividade.titulo, 'Piquenique');
      expect(item.reacoes, const [
        Reacao(tipo: TipoDeReacao.coracao, total: 2, minha: true),
        Reacao(tipo: TipoDeReacao.fogo, total: 1, minha: false),
      ]);
      expect(item.totalDeComentarios, 3);
    },
  );

  test(
    'PaginaDoDiario.deJson traz a capa na primeira página e null nas outras',
    () {
      final primeira = PaginaDoDiario.deJson({
        'itens': [itemJson()],
        'proximo': 'abc',
        'capa': capaJson,
      });
      expect(primeira.capa!.atividades, 2);
      expect(primeira.capa!.paleta, PaletaDoDiario.areia);

      final seguinte = PaginaDoDiario.deJson({
        'itens': [itemJson()],
        'proximo': null,
        'capa': null,
      });
      expect(seguinte.capa, isNull);
    },
  );

  test(
    'comItem troca só o item de mesma atividade e mantém proximo e capa',
    () {
      final pagina = PaginaDoDiario.deJson({
        'itens': [itemJson(id: 'a2'), itemJson(id: 'a1')],
        'proximo': 'abc',
        'capa': capaJson,
      });
      final novo = pagina.itens[1].copyWith(
        reacoes: const [
          Reacao(tipo: TipoDeReacao.festa, total: 1, minha: true),
        ],
        totalDeComentarios: 4,
      );

      final depois = pagina.comItem(novo);

      expect(depois.itens[0], same(pagina.itens[0]));
      expect(depois.itens[1].reacoes.single.tipo, TipoDeReacao.festa);
      expect(depois.itens[1].totalDeComentarios, 4);
      expect(depois.proximo, 'abc');
      expect(depois.capa, same(pagina.capa));
    },
  );

  test('comCapa troca só a capa', () {
    final pagina = PaginaDoDiario.deJson({
      'itens': [itemJson()],
      'proximo': 'abc',
      'capa': capaJson,
    });
    final nova = CapaDoDiario.deJson({
      ...capaJson,
      'titulo': 'Meu diário',
      'paleta': 'ambar',
    });

    final depois = pagina.comCapa(nova);

    expect(depois.capa!.titulo, 'Meu diário');
    expect(depois.capa!.paleta, PaletaDoDiario.ambar);
    expect(depois.itens, same(pagina.itens));
    expect(depois.proximo, 'abc');
  });

  test('copyWith do item muda só o que foi pedido', () {
    final item = ItemDoDiario.deJson(
      itemJson(
        reacoes: const [
          {'tipo': 'coracao', 'total': 2, 'minha': true},
        ],
        comentarios: 3,
      ),
    );
    expect(item.copyWith(totalDeComentarios: 9).reacoes, item.reacoes);
    expect(item.copyWith(reacoes: const []).totalDeComentarios, 3);
    expect(item.copyWith().atividade, same(item.atividade));
  });
}
