import 'pessoa.dart';

/// A foto de alguém numa atividade, com a legenda. As URLs já vêm absolutas da API.
class Registro {
  const Registro({
    required this.id,
    required this.autor,
    required this.fotoUrl,
    required this.miniaturaUrl,
    required this.legenda,
    required this.criadoEm,
  });

  factory Registro.deJson(Map<String, dynamic> json) => Registro(
    id: json['id'] as String,
    autor: Pessoa.deJson(json['autor'] as Map<String, dynamic>),
    fotoUrl: json['foto_url'] as String,
    miniaturaUrl: json['miniatura_url'] as String,
    legenda: json['legenda'] as String,
    criadoEm: DateTime.parse(json['criado_em'] as String),
  );

  final String id;
  final Pessoa autor;
  final String fotoUrl;
  final String miniaturaUrl;
  final String legenda;
  final DateTime criadoEm;
}
