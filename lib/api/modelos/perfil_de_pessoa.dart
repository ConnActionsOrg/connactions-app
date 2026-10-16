import 'pessoa.dart';

/// O perfil de alguém (o meu ou o de uma conexão), como GET /usuarios/{id} devolve: a cara pública,
/// a bio e os três contadores.
class PerfilDePessoa {
  const PerfilDePessoa({
    required this.id,
    required this.handle,
    required this.nome,
    required this.fotoUrl,
    required this.bio,
    required this.turmas,
    required this.atividades,
    required this.conexoes,
  });

  factory PerfilDePessoa.deJson(Map<String, dynamic> json) {
    final contadores = json['contadores'] as Map<String, dynamic>;
    return PerfilDePessoa(
      id: json['id'] as String,
      handle: json['handle'] as String,
      nome: json['nome'] as String,
      fotoUrl: json['foto_url'] as String?,
      bio: json['bio'] as String,
      turmas: contadores['turmas'] as int,
      atividades: contadores['atividades'] as int?,
      conexoes: contadores['conexoes'] as int,
    );
  }

  final String id;
  final String handle;
  final String nome;
  final String? fotoUrl;
  final String bio;
  final int turmas;

  /// Todas as feitas, não só as que eu posso ver. Nulo quando a pessoa as deixou só para si (no meu
  /// próprio perfil, nunca).
  final int? atividades;
  final int conexoes;

  Pessoa get pessoa =>
      Pessoa(id: id, handle: handle, nome: nome, fotoUrl: fotoUrl);
}
