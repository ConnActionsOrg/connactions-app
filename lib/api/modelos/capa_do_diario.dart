import 'turma.dart';

/// As quatro paletas da capa. O slug é o `name`; um slug que o app não conhece vira a padrão.
enum PaletaDoDiario {
  terracota('Terracota'),
  ambar('Âmbar'),
  salvia('Sálvia'),
  areia('Areia');

  const PaletaDoDiario(this.rotulo);

  final String rotulo;

  static const padrao = areia;

  static PaletaDoDiario doSlug(String slug) =>
      values.firstWhere((p) => p.name == slug, orElse: () => padrao);
}

/// Os dez stickers da capa, um emoji cada. O slug é o `name`; um slug desconhecido vira o padrão.
enum StickerDoDiario {
  livro('📖', 'Livro'),
  pizza('🍕', 'Pizza'),
  planta('🌿', 'Planta'),
  cafe('☕', 'Café'),
  cinema('🎬', 'Cinema'),
  praia('🏖️', 'Praia'),
  jogo('🎲', 'Jogo'),
  musica('🎸', 'Música'),
  estrela('⭐', 'Estrela'),
  comida('🌮', 'Comida');

  const StickerDoDiario(this.glifo, this.rotulo);

  final String glifo;
  final String rotulo;

  static const padrao = livro;

  static StickerDoDiario doSlug(String slug) =>
      values.firstWhere((s) => s.name == slug, orElse: () => padrao);
}

/// A capa do Diário da turma: a personalização e os dois contadores. Título e frase são nulos até
/// alguém personalizar.
class CapaDoDiario {
  const CapaDoDiario({
    required this.titulo,
    required this.frase,
    required this.paleta,
    required this.sticker,
    required this.atividades,
    required this.fotos,
  });

  factory CapaDoDiario.deJson(Map<String, dynamic> json) => CapaDoDiario(
    titulo: json['titulo'] as String?,
    frase: json['frase'] as String?,
    paleta: PaletaDoDiario.doSlug(json['paleta'] as String),
    sticker: StickerDoDiario.doSlug(json['sticker'] as String),
    atividades: json['atividades'] as int,
    fotos: json['fotos'] as int,
  );

  final String? titulo;
  final String? frase;
  final PaletaDoDiario paleta;
  final StickerDoDiario sticker;
  final int atividades;
  final int fotos;

  /// O título escolhido, ou "Diário de 🍕 Nome" enquanto ninguém escolheu.
  String tituloPara(Turma turma) =>
      titulo ?? 'Diário de ${turma.emoji} ${turma.nome}';
}

/// O que o PATCH /turmas/{id}/diario pode mudar. Nulo é "não mexe"; título ou frase vazios voltam ao
/// padrão (a API aceita o texto vazio para isso).
class AlteracoesDaCapa {
  const AlteracoesDaCapa({this.titulo, this.frase, this.paleta, this.sticker});

  final String? titulo;
  final String? frase;
  final PaletaDoDiario? paleta;
  final StickerDoDiario? sticker;

  bool get vazia =>
      titulo == null && frase == null && paleta == null && sticker == null;

  Map<String, Object?> toJson() => {
    if (titulo != null) 'titulo': titulo,
    if (frase != null) 'frase': frase,
    if (paleta != null) 'paleta': paleta!.name,
    if (sticker != null) 'sticker': sticker!.name,
  };
}
