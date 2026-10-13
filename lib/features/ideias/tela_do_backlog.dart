import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/ideia.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../atividades/atividade_aberta.dart';
import '../turmas/turmas.dart';
import 'cartao_de_ideia.dart';
import 'ideias.dart';

/// O backlog da turma: as ideias livres de todos os membros, com o autor. Só quem escreveu apaga;
/// quem está na vez, sem atividade aberta, propõe qualquer uma.
class TelaDoBacklog extends ConsumerWidget {
  const TelaDoBacklog({super.key, required this.turmaId});

  final String turmaId;

  Future<void> _apagar(BuildContext context, WidgetRef ref, Ideia ideia) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Apagar esta ideia?'),
        content: const Text('Ela sai do backlog da turma.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    try {
      await ref.read(ideiasProvider(turmaId).notifier).apagar(ideia.id);
    } on ErroDaApi catch (e) {
      if (!context.mounted) return;
      mostrarAviso(context, e.mensagem);
      // um lançamento usou a ideia no meio, ou outro aparelho a apagou: a lista relida diz o que sobrou
      if (e.conflito || e.naoEncontrado) {
        ref.invalidate(ideiasProvider(turmaId));
      }
    } catch (e) {
      if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideias = ref.watch(ideiasProvider(turmaId));
    final euId = ref.watch(perfilAtualProvider).value?.id;
    final turma = ref
        .watch(turmasProvider)
        .value
        ?.where((t) => t.id == turmaId)
        .firstOrNull;
    final aberta = ref.watch(atividadeAbertaProvider(turmaId));
    // sem aberta JÁ carregada: enquanto a leitura não chega, o botão não aparece e some depois
    final podePropor =
        turma != null &&
        turma.vezDe.id == euId &&
        aberta.hasValue &&
        aberta.value == null;
    final lista = ideias.value;
    final erro = ideias.error;
    final Widget corpo;
    if (lista == null && erro != null) {
      corpo = EstadoDeErro(
        mensagem: mensagemDoErro(erro),
        aoTentarDeNovo: () => ref.invalidate(ideiasProvider(turmaId)),
      );
    } else if (lista == null) {
      corpo = const Center(child: CircularProgressIndicator());
    } else if (lista.isEmpty) {
      corpo = EstadoVazio(
        icone: Symbols.lightbulb,
        titulo: 'Nenhuma ideia guardada',
        texto: 'Anote aqui o que a turma quer fazer um dia.',
        acao: FilledButton.icon(
          onPressed: () => context.push('/turmas/$turmaId/ideias/nova'),
          icon: const Icon(Symbols.add),
          label: const Text('Nova ideia'),
        ),
      );
    } else {
      final minhasNoBacklog = euId == null ? 0 : minhasLivres(lista, euId);
      corpo = RefreshIndicator(
        onRefresh: () async {
          try {
            ref.invalidate(ideiasProvider(turmaId));
            await ref.read(ideiasProvider(turmaId).future);
          } catch (e) {
            if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espacos.margemDaTela,
            Espacos.md,
            Espacos.margemDaTela,
            Espacos.xl,
          ),
          children: [
            _Contador(minhas: minhasNoBacklog),
            const SizedBox(height: Espacos.md),
            FilledButton.icon(
              onPressed: minhasNoBacklog >= tetoDeIdeias
                  ? null
                  : () => context.push('/turmas/$turmaId/ideias/nova'),
              icon: const Icon(Symbols.add),
              label: const Text('Nova ideia'),
            ),
            const SizedBox(height: Espacos.lg),
            for (final ideia in lista) ...[
              CartaoDeIdeia(
                ideia: ideia,
                souEu: ideia.autor.id == euId,
                aoApagar: ideia.autor.id == euId
                    ? () => _apagar(context, ref, ideia)
                    : null,
                aoProporEsta: podePropor
                    ? () =>
                          context.push('/turmas/$turmaId/propor', extra: ideia)
                    : null,
              ),
              const SizedBox(height: Espacos.md),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      appBar: const Cabecalho(titulo: 'Backlog de ideias'),
      body: corpo,
    );
  }
}

/// "Suas ideias: 2 de 5", a barra e o que fazer quando enche.
class _Contador extends StatelessWidget {
  const _Contador({required this.minhas});

  final int minhas;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
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
          Text(
            'Suas ideias: $minhas de $tetoDeIdeias',
            style: tipografia.tituloPequeno,
          ),
          const SizedBox(height: Espacos.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: minhas / tetoDeIdeias,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: Espacos.sm),
          Text(
            minhas >= tetoDeIdeias
                ? 'Use ou apague uma para guardar outra.'
                : 'Ideias que a turma guardou para não esquecer.',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
        ],
      ),
    );
  }
}
