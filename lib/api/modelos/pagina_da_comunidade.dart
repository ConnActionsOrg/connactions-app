import 'atividade_da_comunidade.dart';

/// Uma página de GET /comunidade; `proximo` nulo é o fim.
class PaginaDaComunidade {
  const PaginaDaComunidade({required this.itens, required this.proximo});

  factory PaginaDaComunidade.deJson(Map<String, dynamic> json) =>
      PaginaDaComunidade(
        itens: (json['itens'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(AtividadeDaComunidade.deJson)
            .toList(),
        proximo: json['proximo'] as String?,
      );

  final List<AtividadeDaComunidade> itens;
  final String? proximo;
}
