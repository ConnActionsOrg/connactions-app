import 'pessoa.dart';
import 'registro.dart';
import 'turma.dart';

enum FormatoDeAtividade {
  grupo,
  individual;

  static FormatoDeAtividade deJson(String valor) => values.byName(valor);

  /// O texto das etiquetas.
  String get rotulo => switch (this) {
    grupo => 'Em grupo',
    individual => 'Individual',
  };
}

/// A rodada da turma: a proposta de quem estava na vez e os registros que já chegaram. Não há
/// campo de status: aberta é `encerradaEm == null`.
class Atividade {
  const Atividade({
    required this.id,
    required this.turmaId,
    required this.numero,
    required this.proponente,
    required this.titulo,
    required this.descricao,
    required this.regras,
    required this.formato,
    required this.publica,
    required this.prazo,
    required this.lancadaEm,
    required this.encerradaEm,
    required this.registros,
  });

  factory Atividade.deJson(Map<String, dynamic> json) => Atividade(
    id: json['id'] as String,
    turmaId: json['turma_id'] as String,
    numero: json['numero'] as int,
    proponente: Pessoa.deJson(json['proponente'] as Map<String, dynamic>),
    titulo: json['titulo'] as String,
    descricao: json['descricao'] as String,
    regras: (json['regras'] as List<dynamic>).cast<String>(),
    formato: FormatoDeAtividade.deJson(json['formato'] as String),
    publica: json['publica'] as bool,
    prazo: _data(json['prazo']),
    lancadaEm: DateTime.parse(json['lancada_em'] as String),
    encerradaEm: _data(json['encerrada_em']),
    registros: (json['registros'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Registro.deJson)
        .toList(),
  );

  static DateTime? _data(Object? valor) =>
      valor == null ? null : DateTime.parse(valor as String);

  final String id;
  final String turmaId;
  final int numero;
  final Pessoa proponente;
  final String titulo;
  final String descricao;
  final List<String> regras;
  final FormatoDeAtividade formato;
  final bool publica;
  final DateTime? prazo;
  final DateTime lancadaEm;
  final DateTime? encerradaEm;
  final List<Registro> registros;

  bool get aberta => encerradaEm == null;

  /// Sem prazo nunca vence.
  bool prazoVenceu(DateTime agora) {
    final p = prazo;
    return p != null && !agora.isBefore(p);
  }

  Registro? registroDe(String usuarioId) =>
      registros.where((r) => r.autor.id == usuarioId).firstOrNull;

  Atividade copyWith({List<Registro>? registros, DateTime? encerradaEm}) =>
      Atividade(
        id: id,
        turmaId: turmaId,
        numero: numero,
        proponente: proponente,
        titulo: titulo,
        descricao: descricao,
        regras: regras,
        formato: formato,
        publica: publica,
        prazo: prazo,
        lancadaEm: lancadaEm,
        encerradaEm: encerradaEm ?? this.encerradaEm,
        registros: registros ?? this.registros,
      );
}

/// O que POST /atividades/{id}/encerrar devolve: a atividade fechada e a turma já com a vez nova.
class Encerramento {
  const Encerramento({required this.atividade, required this.turma});

  factory Encerramento.deJson(Map<String, dynamic> json) => Encerramento(
    atividade: Atividade.deJson(json['atividade'] as Map<String, dynamic>),
    turma: Turma.deJson(json['turma'] as Map<String, dynamic>),
  );

  final Atividade atividade;
  final Turma turma;
}
