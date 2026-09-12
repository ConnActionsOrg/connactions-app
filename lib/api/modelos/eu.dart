/// O perfil próprio, como a API devolve em /eu.
class Eu {
  const Eu({
    required this.id,
    required this.handle,
    required this.nome,
    required this.fotoUrl,
    required this.bio,
    required this.codigoDeAmigo,
    required this.atividadesVisiveis,
    required this.criadoEm,
  });

  factory Eu.deJson(Map<String, dynamic> json) => Eu(
    id: json['id'] as String,
    handle: json['handle'] as String,
    nome: json['nome'] as String,
    fotoUrl: json['foto_url'] as String?,
    bio: json['bio'] as String,
    codigoDeAmigo: json['codigo_de_amigo'] as String,
    atividadesVisiveis: json['atividades_visiveis'] as bool,
    criadoEm: DateTime.parse(json['criado_em'] as String),
  );

  final String id;
  final String handle;
  final String nome;
  final String? fotoUrl;
  final String bio;
  final String codigoDeAmigo;
  final bool atividadesVisiveis;
  final DateTime criadoEm;

  Eu copyWith({bool? atividadesVisiveis}) => Eu(
    id: id,
    handle: handle,
    nome: nome,
    fotoUrl: fotoUrl,
    bio: bio,
    codigoDeAmigo: codigoDeAmigo,
    atividadesVisiveis: atividadesVisiveis ?? this.atividadesVisiveis,
    criadoEm: criadoEm,
  );
}
