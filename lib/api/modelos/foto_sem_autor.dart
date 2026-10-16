/// A foto de um registro sem quem a postou: é assim que a Comunidade e o perfil de alguém a mostram.
class FotoSemAutor {
  const FotoSemAutor({
    required this.fotoUrl,
    required this.miniaturaUrl,
    required this.legenda,
  });

  factory FotoSemAutor.deJson(Map<String, dynamic> json) => FotoSemAutor(
    fotoUrl: json['foto_url'] as String,
    miniaturaUrl: json['miniatura_url'] as String,
    legenda: json['legenda'] as String,
  );

  final String fotoUrl;
  final String miniaturaUrl;
  final String legenda;
}
