import 'dart:typed_data';

/// A foto escolhida no aparelho, já encolhida pelo seletor, pronta para o multipart.
class FotoParaEnviar {
  const FotoParaEnviar({required this.bytes, required this.nome});

  final Uint8List bytes;
  final String nome;
}
