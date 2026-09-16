/// O que o PATCH /eu pode mudar. Só o que não é nulo vai no JSON.
class AlteracoesDoEu {
  const AlteracoesDoEu({
    this.nome,
    this.handle,
    this.bio,
    this.atividadesVisiveis,
  });

  final String? nome;
  final String? handle;
  final String? bio;
  final bool? atividadesVisiveis;

  bool get vazia =>
      nome == null &&
      handle == null &&
      bio == null &&
      atividadesVisiveis == null;

  Map<String, Object?> toJson() => {
    if (nome != null) 'nome': nome,
    if (handle != null) 'handle': handle,
    if (bio != null) 'bio': bio,
    if (atividadesVisiveis != null) 'atividades_visiveis': atividadesVisiveis,
  };
}
