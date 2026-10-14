import 'package:flutter/material.dart';

import '../cores.dart';

/// Emoji centrado num disco tonal: a "foto" de uma turma.
class DiscoDeEmoji extends StatelessWidget {
  const DiscoDeEmoji({
    super.key,
    required this.emoji,
    this.tamanho = 48,
    this.cor,
  });

  final String emoji;
  final double tamanho;

  /// O disco de uma turma é tonal; o sticker da capa do Diário traz o da sua paleta.
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor ?? cores.superficieContainer,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: tamanho * 0.5, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}
