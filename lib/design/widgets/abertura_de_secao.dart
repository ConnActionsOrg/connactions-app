import 'package:flutter/material.dart';

import '../cores.dart';
import '../medidas.dart';
import '../tipografia.dart';

/// Título editorial que orienta a leitura sem acrescentar ações à tela.
class AberturaDeSecao extends StatelessWidget {
  const AberturaDeSecao({
    super.key,
    required this.titulo,
    required this.descricao,
  });

  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipos = Tipografia.de(context);
    return Padding(
      padding: const EdgeInsets.only(top: Espacos.sm, bottom: Espacos.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: tipos.displayGrande),
          const SizedBox(height: 6),
          Text(
            descricao,
            style: tipos.corpoMedio.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
        ],
      ),
    );
  }
}
