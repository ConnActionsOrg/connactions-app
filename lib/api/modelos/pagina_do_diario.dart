import 'atividade.dart';
import 'capa_do_diario.dart';
import 'reacao.dart';

/// Uma encerrada no Diário: a atividade com o resumo das reações (visto por quem pediu) e o total de
/// comentários. Os comentários em si só são buscados quando a folha abre.
class ItemDoDiario {
  const ItemDoDiario({
    required this.atividade,
    required this.reacoes,
    required this.totalDeComentarios,
  });

  /// O item é a atividade com dois campos a mais: o mesmo objeto JSON serve aos dois.
  factory ItemDoDiario.deJson(Map<String, dynamic> json) => ItemDoDiario(
    atividade: Atividade.deJson(json),
    reacoes: Reacao.listaDeJson(json['reacoes'] as List<dynamic>),
    totalDeComentarios: json['total_de_comentarios'] as int,
  );

  final Atividade atividade;
  final List<Reacao> reacoes;
  final int totalDeComentarios;

  ItemDoDiario copyWith({List<Reacao>? reacoes, int? totalDeComentarios}) =>
      ItemDoDiario(
        atividade: atividade,
        reacoes: reacoes ?? this.reacoes,
        totalDeComentarios: totalDeComentarios ?? this.totalDeComentarios,
      );
}

/// Uma página de GET /turmas/{id}/diario; `proximo` nulo é o fim. A `capa` só vem na primeira página.
class PaginaDoDiario {
  const PaginaDoDiario({required this.itens, required this.proximo, this.capa});

  factory PaginaDoDiario.deJson(Map<String, dynamic> json) => PaginaDoDiario(
    itens: (json['itens'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ItemDoDiario.deJson)
        .toList(),
    proximo: json['proximo'] as String?,
    capa: json['capa'] == null
        ? null
        : CapaDoDiario.deJson(json['capa'] as Map<String, dynamic>),
  );

  final List<ItemDoDiario> itens;
  final String? proximo;
  final CapaDoDiario? capa;

  /// Troca o item de mesma atividade; as outras páginas e a capa ficam como estão.
  PaginaDoDiario comItem(ItemDoDiario novo) => PaginaDoDiario(
    itens: [
      for (final item in itens)
        if (item.atividade.id == novo.atividade.id) novo else item,
    ],
    proximo: proximo,
    capa: capa,
  );

  PaginaDoDiario comCapa(CapaDoDiario nova) =>
      PaginaDoDiario(itens: itens, proximo: proximo, capa: nova);
}
