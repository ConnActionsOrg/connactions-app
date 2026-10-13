import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/etiqueta.dart';
import 'ideias.dart';

/// O atalho do Feed para o backlog: a lâmpada do Stitch, o convite para sugerir e as minhas ideias
/// livres ("N/5"). Enquanto as ideias carregam, ou se a leitura falhou, aparece sem o número.
class CartaoDoBacklog extends ConsumerWidget {
  const CartaoDoBacklog({super.key, required this.turmaId});

  final String turmaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final ideias = ref.watch(ideiasProvider(turmaId)).value;
    final euId = ref.watch(perfilAtualProvider).value?.id;
    final minhas = ideias == null || euId == null
        ? null
        : minhasLivres(ideias, euId);
    return Container(
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.medio),
        boxShadow: Sombras.nivel1,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push('/turmas/$turmaId/ideias'),
          borderRadius: BorderRadius.circular(Raios.medio),
          child: Padding(
            padding: const EdgeInsets.all(Espacos.cartao),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cores.secundariaFixa,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.lightbulb,
                    color: cores.sobreSecundariaFixa,
                  ),
                ),
                const SizedBox(width: Espacos.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Backlog de ideias', style: tipografia.rotuloTitulo),
                      Text(
                        'Sugira novos rolês para a turma',
                        style: tipografia.corpoPequeno.copyWith(
                          color: cores.sobreSuperficieVariante,
                        ),
                      ),
                    ],
                  ),
                ),
                if (minhas != null) ...[
                  const SizedBox(width: Espacos.sm),
                  Etiqueta(texto: '$minhas/$tetoDeIdeias'),
                ],
                Icon(
                  Symbols.chevron_right,
                  color: cores.sobreSuperficieVariante,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
