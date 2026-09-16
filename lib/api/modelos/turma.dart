import 'pessoa.dart';

/// A turma como a lista e a pílula precisam dela (o resumo da API).
class Turma {
  const Turma({
    required this.id,
    required this.nome,
    required this.emoji,
    required this.codigoConvite,
    required this.criadorId,
    required this.vezDe,
    required this.totalDeMembros,
    required this.criadoEm,
  });

  factory Turma.deJson(Map<String, dynamic> json) => Turma(
    id: json['id'] as String,
    nome: json['nome'] as String,
    emoji: json['emoji'] as String,
    codigoConvite: json['codigo_convite'] as String,
    criadorId: json['criador_id'] as String,
    vezDe: Pessoa.deJson(json['vez_de'] as Map<String, dynamic>),
    totalDeMembros: json['total_de_membros'] as int,
    criadoEm: DateTime.parse(json['criado_em'] as String),
  );

  final String id;
  final String nome;
  final String emoji;
  final String codigoConvite;
  final String criadorId;
  final Pessoa vezDe;
  final int totalDeMembros;
  final DateTime criadoEm;

  Turma copyWith({String? codigoConvite, Pessoa? vezDe, int? totalDeMembros}) =>
      Turma(
        id: id,
        nome: nome,
        emoji: emoji,
        codigoConvite: codigoConvite ?? this.codigoConvite,
        criadorId: criadorId,
        vezDe: vezDe ?? this.vezDe,
        totalDeMembros: totalDeMembros ?? this.totalDeMembros,
        criadoEm: criadoEm,
      );

  /// "1 membro" / "N membros": a pílula, a folha e a tela da turma dizem igual.
  String get membrosPorExtenso =>
      totalDeMembros == 1 ? '1 membro' : '$totalDeMembros membros';
}

class Membro {
  const Membro({
    required this.pessoa,
    required this.ordem,
    required this.entrouEm,
  });

  /// O JSON do membro é a pessoa com ordem e entrou_em no mesmo nível.
  factory Membro.deJson(Map<String, dynamic> json) => Membro(
    pessoa: Pessoa.deJson(json),
    ordem: json['ordem'] as int,
    entrouEm: DateTime.parse(json['entrou_em'] as String),
  );

  final Pessoa pessoa;
  final int ordem;
  final DateTime entrouEm;
}

class TurmaDetalhe {
  const TurmaDetalhe({required this.turma, required this.membros});

  factory TurmaDetalhe.deJson(Map<String, dynamic> json) => TurmaDetalhe(
    turma: Turma.deJson(json),
    membros: (json['membros'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Membro.deJson)
        .toList(),
  );

  final Turma turma;
  final List<Membro> membros;
}
