import 'atividade.dart';

/// O corpo de POST /turmas/{id}/atividades.
class Proposta {
  const Proposta({
    required this.titulo,
    this.descricao = '',
    this.regras = const [],
    required this.formato,
    required this.publica,
    this.prazo,
    this.origemIdeiaId,
    this.origemAtividadeId,
  });

  final String titulo;
  final String descricao;
  final List<String> regras;
  final FormatoDeAtividade formato;
  final bool publica;
  final DateTime? prazo;

  /// No máximo uma das duas: a ideia do backlog ou a atividade da Comunidade que originou a proposta.
  final String? origemIdeiaId;
  final String? origemAtividadeId;

  Map<String, Object?> toJson() => {
    'titulo': titulo,
    'descricao': descricao,
    if (regras.isNotEmpty) 'regras': regras,
    'formato': formato.name,
    'publica': publica,
    if (prazo != null) 'prazo': prazo!.toUtc().toIso8601String(),
    'origem_ideia_id': ?origemIdeiaId,
    'origem_atividade_id': ?origemAtividadeId,
  };
}
