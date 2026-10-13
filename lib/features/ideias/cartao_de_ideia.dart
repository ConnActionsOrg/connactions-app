import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/ideia.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/etiqueta.dart';

/// Uma ideia do backlog: título, descrição, quem sugeriu e, quando há, a origem e o formato. A tela
/// do backlog liga o "Apagar" nas minhas; o Propor só liga o "Propor esta".
class CartaoDeIdeia extends StatelessWidget {
  const CartaoDeIdeia({
    super.key,
    required this.ideia,
    required this.souEu,
    this.aoApagar,
    this.aoProporEsta,
  });

  final Ideia ideia;
  final bool souEu;
  final VoidCallback? aoApagar;
  final VoidCallback? aoProporEsta;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final formato = ideia.formato;
    return Container(
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.medio),
        boxShadow: Sombras.nivel1,
      ),
      padding: const EdgeInsets.all(Espacos.cartao),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ideia.titulo, style: tipografia.tituloPequeno),
          if (ideia.descricao.isNotEmpty) ...[
            const SizedBox(height: Espacos.xs),
            Text(ideia.descricao, style: tipografia.corpoMedio),
          ],
          const SizedBox(height: Espacos.sm),
          Wrap(
            spacing: Espacos.sm,
            runSpacing: Espacos.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                souEu
                    ? 'Sua ideia'
                    : 'Sugerido por ${ideia.autor.primeiroNome}',
                style: tipografia.corpoPequeno.copyWith(
                  color: cores.sobreSuperficieVariante,
                ),
              ),
              if (ideia.daComunidade)
                const Etiqueta(
                  texto: 'Da Comunidade',
                  tom: TomDaEtiqueta.salvia,
                ),
              if (formato != null)
                Etiqueta(texto: formato.rotulo, tom: TomDaEtiqueta.ambar),
            ],
          ),
          if (aoProporEsta != null || aoApagar != null)
            const SizedBox(height: Espacos.md),
          // em coluna: o tema dá largura mínima infinita aos botões cheios, e numa Row eles estourariam
          if (aoProporEsta != null)
            FilledButton.icon(
              onPressed: aoProporEsta,
              icon: const Icon(Symbols.arrow_forward),
              label: const Text('Propor esta'),
            ),
          if (aoApagar != null)
            TextButton.icon(
              onPressed: aoApagar,
              icon: const Icon(Symbols.delete),
              label: const Text('Apagar'),
            ),
        ],
      ),
    );
  }
}
