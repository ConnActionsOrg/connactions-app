import 'package:flutter/material.dart';

import '../cores.dart';

/// Emoji centrado num disco tonal: a "foto" de uma turma.
class DiscoDeEmoji extends StatelessWidget {
  const DiscoDeEmoji({super.key, required this.emoji, this.tamanho = 48});

  final String emoji;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cores.superficieContainer,
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
