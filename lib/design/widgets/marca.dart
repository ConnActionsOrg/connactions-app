import 'package:flutter/material.dart';

/// Arquivo oficial fornecido pelo autor. Usado sem redesenhar ou recolorir a marca.
class Marca extends StatelessWidget {
  const Marca({super.key, this.tamanho = 32});
  final double tamanho;
  static const caminho = 'assets/marca/connactions.png';

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ConnActions',
    image: true,
    child: Image.asset(
      caminho,
      width: tamanho,
      height: tamanho,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.high,
    ),
  );
}
