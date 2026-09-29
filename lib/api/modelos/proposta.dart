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
  });

  final String titulo;
  final String descricao;
  final List<String> regras;
  final FormatoDeAtividade formato;
  final bool publica;
  final DateTime? prazo;

  Map<String, Object?> toJson() => {
    'titulo': titulo,
    'descricao': descricao,
    if (regras.isNotEmpty) 'regras': regras,
    'formato': formato.name,
    'publica': publica,
    if (prazo != null) 'prazo': prazo!.toUtc().toIso8601String(),
  };
}
