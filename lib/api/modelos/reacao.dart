/// As seis reações. O slug é o contrato com a API, nunca o emoji: o ❤️ tem seletor de variação
/// (U+FE0F), que se perde em URL e proxy.
enum TipoDeReacao {
  coracao('coracao', '❤️', 'Coração'),
  risada('risada', '😂', 'Risada'),
  apaixonado('apaixonado', '😍', 'Apaixonado'),
  palmas('palmas', '👏', 'Palmas'),
  fogo('fogo', '🔥', 'Fogo'),
  festa('festa', '🥳', 'Festa');

  const TipoDeReacao(this.slug, this.glifo, this.rotulo);

  final String slug;
  final String glifo;

  /// O nome para o leitor de tela e a dica do botão.
  final String rotulo;

  /// Slug que o app não conhece (servidor mais novo que o app) vira nulo, e quem lê descarta a reação
  /// em vez de estourar o Diário inteiro.
  static TipoDeReacao? doSlug(String slug) {
    for (final tipo in values) {
      if (tipo.slug == slug) return tipo;
    }
    return null;
  }
}

/// O resumo de um tipo numa atividade: quantas pessoas reagiram e se uma delas sou eu.
class Reacao {
  const Reacao({required this.tipo, required this.total, required this.minha});

  /// Nulo quando o tipo é desconhecido: ver [TipoDeReacao.doSlug].
  static Reacao? deJson(Map<String, dynamic> json) {
    final tipo = TipoDeReacao.doSlug(json['tipo'] as String);
    if (tipo == null) return null;
    return Reacao(
      tipo: tipo,
      total: json['total'] as int,
      minha: json['minha'] as bool,
    );
  }

  /// O `reacoes` de uma resposta da API, sem as que o app não conhece.
  static List<Reacao> listaDeJson(List<dynamic> json) => [
    for (final r in json.cast<Map<String, dynamic>>()) ?Reacao.deJson(r),
  ];

  final TipoDeReacao tipo;
  final int total;
  final bool minha;

  @override
  bool operator ==(Object other) =>
      other is Reacao &&
      other.tipo == tipo &&
      other.total == total &&
      other.minha == minha;

  @override
  int get hashCode => Object.hash(tipo, total, minha);

  @override
  String toString() => 'Reacao(${tipo.slug} $total, minha: $minha)';
}
