import 'package:flutter/material.dart';

import '../cores.dart';
import '../medidas.dart';
import '../tipografia.dart';

/// Estado vazio de uma tela: ícone num disco, título e, se houver, uma frase e a ação que povoa.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.texto,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String? texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final texto = this.texto;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espacos.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cores.superficieContainer,
              ),
              alignment: Alignment.center,
              child: Icon(icone, size: 32, color: cores.primaria),
            ),
            const SizedBox(height: Espacos.md),
            Text(
              titulo,
              style: tipografia.tituloPequeno,
              textAlign: TextAlign.center,
            ),
            if (texto != null) ...[
              const SizedBox(height: Espacos.sm),
              Text(
                texto,
                style: tipografia.corpoMedio.copyWith(
                  color: cores.sobreSuperficieVariante,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (acao != null) ...[const SizedBox(height: Espacos.lg), acao!],
          ],
        ),
      ),
    );
  }
}
