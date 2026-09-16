/// A cara pública de um usuário: o que aparece em "vez de" e na lista de membros.
class Pessoa {
  const Pessoa({
    required this.id,
    required this.handle,
    required this.nome,
    required this.fotoUrl,
  });

  factory Pessoa.deJson(Map<String, dynamic> json) => Pessoa(
    id: json['id'] as String,
    handle: json['handle'] as String,
    nome: json['nome'] as String,
    fotoUrl: json['foto_url'] as String?,
  );

  final String id;
  final String handle;
  final String nome;
  final String? fotoUrl;

  /// "Marina Duarte" → "Marina".
  String get primeiroNome => nome.trim().split(RegExp(r'\s+')).first;
}
