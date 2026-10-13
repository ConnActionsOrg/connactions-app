import 'atividade.dart';
import 'pessoa.dart';

/// Uma ideia do backlog da turma. A digitada tem só título e descrição (formato nulo, regras
/// vazias); a salva da Comunidade traz também formato, regras e a atividade de origem.
class Ideia {
  const Ideia({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.regras,
    required this.formato,
    required this.origemAtividadeId,
    required this.autor,
    required this.criadoEm,
  });

  factory Ideia.deJson(Map<String, dynamic> json) => Ideia(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    descricao: json['descricao'] as String,
    regras: (json['regras'] as List<dynamic>).cast<String>(),
    formato: switch (json['formato']) {
      final String valor => FormatoDeAtividade.deJson(valor),
      _ => null,
    },
    origemAtividadeId: json['origem_atividade_id'] as String?,
    autor: Pessoa.deJson(json['autor'] as Map<String, dynamic>),
    criadoEm: DateTime.parse(json['criado_em'] as String),
  );

  final String id;
  final String titulo;
  final String descricao;
  final List<String> regras;
  final FormatoDeAtividade? formato;
  final String? origemAtividadeId;
  final Pessoa autor;
  final DateTime criadoEm;

  /// A etiqueta "Da Comunidade". A API zera a origem se a turma de origem sumir.
  bool get daComunidade => origemAtividadeId != null;
}
