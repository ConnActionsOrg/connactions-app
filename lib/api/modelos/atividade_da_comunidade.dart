import 'atividade.dart';

/// A foto de um registro como a Comunidade a mostra: sem autor.
class FotoDaComunidade {
  const FotoDaComunidade({
    required this.fotoUrl,
    required this.miniaturaUrl,
    required this.legenda,
  });

  factory FotoDaComunidade.deJson(Map<String, dynamic> json) =>
      FotoDaComunidade(
        fotoUrl: json['foto_url'] as String,
        miniaturaUrl: json['miniatura_url'] as String,
        legenda: json['legenda'] as String,
      );

  final String fotoUrl;
  final String miniaturaUrl;
  final String legenda;
}

/// Uma atividade pública e encerrada de outra turma. Não há campo de pessoa nem id de turma: o app
/// não tem onde guardar o que a API não manda.
class AtividadeDaComunidade {
  const AtividadeDaComunidade({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.regras,
    required this.formato,
    required this.encerradaEm,
    required this.turmaNome,
    required this.turmaEmoji,
    required this.fotos,
    required this.inspiradas,
  });

  factory AtividadeDaComunidade.deJson(Map<String, dynamic> json) {
    final turma = json['turma'] as Map<String, dynamic>;
    return AtividadeDaComunidade(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      regras: (json['regras'] as List<dynamic>).cast<String>(),
      formato: FormatoDeAtividade.deJson(json['formato'] as String),
      encerradaEm: DateTime.parse(json['encerrada_em'] as String),
      turmaNome: turma['nome'] as String,
      turmaEmoji: turma['emoji'] as String,
      fotos: (json['fotos'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(FotoDaComunidade.deJson)
          .toList(),
      inspiradas: json['inspiradas'] as int,
    );
  }

  final String id;
  final String titulo;
  final String descricao;
  final List<String> regras;
  final FormatoDeAtividade formato;
  final DateTime encerradaEm;
  final String turmaNome;
  final String turmaEmoji;
  final List<FotoDaComunidade> fotos;

  /// Turmas distintas que se inspiraram nesta atividade; muda na próxima carga da lista.
  final int inspiradas;
}
