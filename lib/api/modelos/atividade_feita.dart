import 'atividade.dart';
import 'foto_sem_autor.dart';

/// Uma atividade encerrada no perfil de alguém: o que foi, de que turma, quando acabou e as fotos sem
/// autor, as da dona do perfil primeiro. Sem reações nem comentários, que são do Diário da turma.
class AtividadeFeita {
  const AtividadeFeita({
    required this.id,
    required this.titulo,
    required this.formato,
    required this.encerradaEm,
    required this.turmaNome,
    required this.turmaEmoji,
    required this.fotos,
  });

  factory AtividadeFeita.deJson(Map<String, dynamic> json) {
    final turma = json['turma'] as Map<String, dynamic>;
    return AtividadeFeita(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      formato: FormatoDeAtividade.deJson(json['formato'] as String),
      encerradaEm: DateTime.parse(json['encerrada_em'] as String),
      turmaNome: turma['nome'] as String,
      turmaEmoji: turma['emoji'] as String,
      fotos: (json['fotos'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(FotoSemAutor.deJson)
          .toList(),
    );
  }

  final String id;
  final String titulo;
  final FormatoDeAtividade formato;
  final DateTime encerradaEm;
  final String turmaNome;
  final String turmaEmoji;
  final List<FotoSemAutor> fotos;
}

/// Uma página de GET /usuarios/{id}/atividades; `proximo` nulo é o fim.
class PaginaDeAtividadesFeitas {
  const PaginaDeAtividadesFeitas({required this.itens, required this.proximo});

  factory PaginaDeAtividadesFeitas.deJson(Map<String, dynamic> json) =>
      PaginaDeAtividadesFeitas(
        itens: (json['itens'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(AtividadeFeita.deJson)
            .toList(),
        proximo: json['proximo'] as String?,
      );

  final List<AtividadeFeita> itens;
  final String? proximo;
}
