import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/cores.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/disco_de_emoji.dart';
import 'folha_de_turmas.dart';
import 'turmas.dart';

/// A pílula da turma ativa. Só existe quando há turma; tocar abre a folha para trocar.
class SeletorDeTurma extends ConsumerWidget {
  const SeletorDeTurma({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turma = ref.watch(turmaAtivaProvider);
    if (turma == null) return const SizedBox.shrink();
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Semantics(
      button: true,
      label: 'Trocar de turma',
      child: Material(
        color: cores.superficieContainer,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => mostrarFolhaDeTurmas(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              children: [
                DiscoDeEmoji(emoji: turma.emoji, tamanho: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turma.nome,
                        style: tipografia.rotuloTitulo,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${turma.membrosPorExtenso} · vez de ${turma.vezDe.primeiroNome}',
                        style: tipografia.corpoPequeno.copyWith(
                          color: cores.sobreSuperficieVariante,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Symbols.unfold_more, color: cores.sobreSuperficieVariante),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
