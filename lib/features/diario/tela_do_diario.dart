import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/turma.dart';
import '../../app/relogio.dart';
import '../../design/medidas.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/botao_carregar_mais.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../turmas/seletor_de_turma.dart';
import '../turmas/turmas.dart';
import 'cartao_do_diario.dart';
import 'diario.dart';

/// O Diário é por turma: a mesma pílula do Feed escolhe qual. Lista as encerradas, página a página.
class TelaDoDiario extends ConsumerWidget {
  const TelaDoDiario({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turma = ref.watch(turmaAtivaProvider);
    return Scaffold(
      appBar: const Cabecalho(),
      body: turma == null
          ? const EstadoVazio(
              icone: Symbols.auto_stories,
              titulo: 'O diário começa vazio',
              texto: 'Cada atividade encerrada vira uma memória da turma aqui.',
            )
          : _ComTurma(turma: turma),
    );
  }
}

class _ComTurma extends ConsumerWidget {
  const _ComTurma({required this.turma});

  final Turma turma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagina = ref.watch(diarioProvider(turma.id));
    final agora = ref.watch(relogioProvider)();
    final itens = pagina.value?.itens;
    final erro = pagina.error;
    final List<Widget> corpo;
    if (itens == null && erro != null) {
      corpo = [
        EstadoDeErro(
          mensagem: mensagemDoErro(erro),
          aoTentarDeNovo: () => ref.invalidate(diarioProvider(turma.id)),
        ),
      ];
    } else if (itens == null) {
      corpo = [const Center(child: CircularProgressIndicator())];
    } else if (itens.isEmpty) {
      corpo = [
        EstadoVazio(
          icone: Symbols.auto_stories,
          titulo: 'O diário da turma começa vazio',
          texto:
              'As atividades encerradas de ${turma.emoji} ${turma.nome} vão aparecer aqui.',
        ),
      ];
    } else {
      corpo = [
        for (final atividade in itens) ...[
          CartaoDoDiario(atividade: atividade, agora: agora),
          const SizedBox(height: Espacos.md),
        ],
        if (pagina.value?.proximo != null)
          BotaoCarregarMais(
            aoCarregar: () =>
                ref.read(diarioProvider(turma.id).notifier).carregarMais(),
          ),
      ];
    }
    return RefreshIndicator(
      onRefresh: () async {
        try {
          ref.invalidate(diarioProvider(turma.id));
          await ref.read(diarioProvider(turma.id).future);
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
          const SeletorDeTurma(),
          const SizedBox(height: Espacos.xl),
          ...corpo,
        ],
      ),
    );
  }
}
