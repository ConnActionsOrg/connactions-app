import 'package:flutter/material.dart';

import '../../api/modelos/pessoa.dart';
import '../cores.dart';
import '../tipografia.dart';
import 'avatar.dart';

/// Até `maximo` avatares sobrepostos e um disco "+N" com o que sobrou.
class PilhaDeAvatares extends StatelessWidget {
  const PilhaDeAvatares({
    super.key,
    required this.pessoas,
    this.tamanho = 32,
    this.maximo = 4,
  });

  final List<Pessoa> pessoas;
  final double tamanho;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final visiveis = pessoas.take(maximo).toList();
    final sobra = pessoas.length - visiveis.length;
    final discos = visiveis.length + (sobra > 0 ? 1 : 0);
    if (discos == 0) return SizedBox(height: tamanho);
    final passo = tamanho * 0.7;
    return SizedBox(
      height: tamanho,
      width: passo * (discos - 1) + tamanho,
      child: Stack(
        children: [
          for (final (i, pessoa) in visiveis.indexed)
            Positioned(
              left: i * passo,
              child: Avatar(
                nome: pessoa.nome,
                fotoUrl: pessoa.fotoUrl,
                tamanho: tamanho,
              ),
            ),
          if (sobra > 0)
            Positioned(
              left: visiveis.length * passo,
              child: _Sobra(quantos: sobra, tamanho: tamanho),
            ),
        ],
      ),
    );
  }
}

class _Sobra extends StatelessWidget {
  const _Sobra({required this.quantos, required this.tamanho});

  final int quantos;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cores.superficieAlta,
        border: Border.all(color: cores.superficieMaisBaixa, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$quantos',
        style: tipografia.etiquetaPequena.copyWith(
          color: cores.sobreSuperficieVariante,
        ),
      ),
    );
  }
}
