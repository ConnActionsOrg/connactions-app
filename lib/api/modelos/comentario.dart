import 'pessoa.dart';

/// Um comentário numa atividade encerrada. `meu` diz quem vê o botão de apagar.
class Comentario {
  const Comentario({
    required this.id,
    required this.autor,
    required this.texto,
    required this.criadoEm,
    required this.meu,
  });

  factory Comentario.deJson(Map<String, dynamic> json) => Comentario(
    id: json['id'] as String,
    autor: Pessoa.deJson(json['autor'] as Map<String, dynamic>),
    texto: json['texto'] as String,
    criadoEm: DateTime.parse(json['criado_em'] as String),
    meu: json['meu'] as bool,
  );

  final String id;
  final Pessoa autor;
  final String texto;
  final DateTime criadoEm;
  final bool meu;
}

/// Uma página de GET /atividades/{id}/comentarios, do mais antigo para o mais novo; `proximo` nulo é
/// o fim.
class PaginaDeComentarios {
  const PaginaDeComentarios({required this.itens, required this.proximo});

  factory PaginaDeComentarios.deJson(Map<String, dynamic> json) =>
      PaginaDeComentarios(
        itens: (json['itens'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Comentario.deJson)
            .toList(),
        proximo: json['proximo'] as String?,
      );

  final List<Comentario> itens;
  final String? proximo;
}
