import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../cores.dart';
import '../medidas.dart';
import '../tipografia.dart';

/// Falha ao carregar uma tela: diz o que houve e oferece tentar de novo.
class EstadoDeErro extends StatelessWidget {
  const EstadoDeErro({
    super.key,
    required this.mensagem,
    required this.aoTentarDeNovo,
  });

  final String mensagem;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
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
                color: cores.erroContainer,
              ),
              alignment: Alignment.center,
              child: Icon(
                Symbols.error,
                size: 32,
                color: cores.sobreErroContainer,
              ),
            ),
            const SizedBox(height: Espacos.md),
            Text(
              'Algo não deu certo',
              style: tipografia.tituloPequeno,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Espacos.sm),
            Text(
              mensagem,
              style: tipografia.corpoMedio.copyWith(
                color: cores.sobreSuperficieVariante,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Espacos.lg),
            FilledButton(
              onPressed: aoTentarDeNovo,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
