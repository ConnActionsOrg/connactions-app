import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/turma.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/disco_de_emoji.dart';
import '../../design/widgets/etiqueta.dart';
import 'turma_ativa.dart';
import 'turmas.dart';

Future<void> mostrarFolhaDeTurmas(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FolhaDeTurmas(),
    );

/// Todas as minhas turmas; tocar troca a ativa. Criar e entrar ficam no rodapé.
class FolhaDeTurmas extends ConsumerWidget {
  const FolhaDeTurmas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turmas = ref.watch(turmasProvider).value ?? const <Turma>[];
    final ativa = ref.watch(turmaAtivaProvider);
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    // capturado antes do pop: depois dele o contexto da folha morre, e o push precisa do roteador
    final roteador = GoRouter.of(context);
    void fecharEIr(String rota) {
      Navigator.of(context).pop();
      roteador.push<void>(rota);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacos.margemDaTela,
        0,
        Espacos.margemDaTela,
        Espacos.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suas turmas', style: tipografia.tituloMedio),
          Text(
            'Toque para trocar a turma ativa',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          const SizedBox(height: Espacos.md),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: turmas.length,
              separatorBuilder: (_, _) => const SizedBox(height: Espacos.sm),
              itemBuilder: (_, i) {
                final turma = turmas[i];
                final ehAtiva = turma.id == ativa?.id;
                return CartaoDeTurma(
                  turma: turma,
                  ativa: ehAtiva,
                  aoTocar: () async {
                    if (!ehAtiva) {
                      await ref
                          .read(turmaAtivaIdProvider.notifier)
                          .definir(turma.id);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  aoVerTurma: () => fecharEIr('/turmas/${turma.id}'),
                );
              },
            ),
          ),
          const SizedBox(height: Espacos.md),
          FilledButton.icon(
            onPressed: () => fecharEIr('/turmas/nova'),
            icon: const Icon(Symbols.add),
            label: const Text('Criar nova turma'),
          ),
          TextButton.icon(
            onPressed: () => fecharEIr('/turmas/entrar'),
            icon: const Icon(Symbols.key),
            label: const Text('Entrar com código de convite'),
          ),
        ],
      ),
    );
  }
}

class CartaoDeTurma extends StatelessWidget {
  const CartaoDeTurma({
    super.key,
    required this.turma,
    required this.ativa,
    required this.aoTocar,
    required this.aoVerTurma,
  });

  final Turma turma;
  final bool ativa;
  final VoidCallback aoTocar;
  final VoidCallback aoVerTurma;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Material(
      color: cores.superficieBaixa,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raios.medio),
        side: ativa
            ? BorderSide(color: cores.primaria, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(Raios.medio),
        child: Padding(
          padding: const EdgeInsets.all(Espacos.md),
          child: Row(
            children: [
              DiscoDeEmoji(emoji: turma.emoji, tamanho: 48),
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
              if (ativa) const Etiqueta(texto: 'Ativa'),
              IconButton(
                onPressed: aoVerTurma,
                tooltip: 'Ver turma',
                icon: Icon(
                  Symbols.chevron_right,
                  color: cores.sobreSuperficieVariante,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
