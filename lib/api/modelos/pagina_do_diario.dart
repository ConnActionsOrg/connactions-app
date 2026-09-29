import 'atividade.dart';

/// Uma página de GET /turmas/{id}/diario; `proximo` nulo é o fim.
class PaginaDoDiario {
  const PaginaDoDiario({required this.itens, required this.proximo});

  factory PaginaDoDiario.deJson(Map<String, dynamic> json) => PaginaDoDiario(
    itens: (json['itens'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Atividade.deJson)
        .toList(),
    proximo: json['proximo'] as String?,
  );

  final List<Atividade> itens;
  final String? proximo;
}
