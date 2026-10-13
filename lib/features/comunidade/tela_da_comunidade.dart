import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../app/relogio.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/botao_carregar_mais.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../ideias/ideias.dart';
import '../turmas/seletor_de_turma.dart';
import '../turmas/turmas.dart';
import 'cartao_da_comunidade.dart';
import 'comunidade.dart';

/// A Comunidade: atividades públicas de outras turmas. A pílula do topo é a turma que recebe o que
/// se salva e propõe; sem turma, dá para ler mas não agir.
class TelaDaComunidade extends ConsumerWidget {
  const TelaDaComunidade({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ativa = ref.watch(turmaAtivaProvider);
    final pagina = ref.watch(comunidadeProvider);
    final agora = ref.watch(relogioProvider)();
    final itens = pagina.value?.itens;
    final erro = pagina.error;
    final List<Widget> corpo;
    if (itens == null && erro != null) {
      corpo = [
        EstadoDeErro(
          mensagem: mensagemDoErro(erro),
          aoTentarDeNovo: () {
            // a falha pode ter nascido no perfil ou nas turmas, que a lista espera
            ref.invalidate(perfilAtualProvider);
            ref.invalidate(turmasProvider);
            ref.invalidate(comunidadeProvider);
          },
        ),
      ];
    } else if (itens == null) {
      corpo = [const Center(child: CircularProgressIndicator())];
    } else if (itens.isEmpty) {
      corpo = [
        const EstadoVazio(
          icone: Symbols.groups_2,
          titulo: 'A comunidade ainda está quieta',
          texto:
              'Atividades públicas das outras turmas vão aparecer aqui para inspirar a sua.',
        ),
      ];
    } else {
      corpo = [
        for (final atividade in itens) ...[
          CartaoDaComunidade(
            atividade: atividade,
            agora: agora,
            turmaAtiva: ativa,
          ),
          const SizedBox(height: Espacos.md),
        ],
        if (pagina.value?.proximo != null)
          BotaoCarregarMais(
            aoCarregar: () =>
                ref.read(comunidadeProvider.notifier).carregarMais(),
          ),
      ];
    }
    return Scaffold(
      appBar: const Cabecalho(),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await Future.wait<Object?>([
              ref.refresh(comunidadeProvider.future),
              if (ativa != null) ref.refresh(ideiasProvider(ativa.id).future),
            ]);
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
            if (ativa != null)
              const SeletorDeTurma()
            else
              const _FaixaSemTurma(),
            const SizedBox(height: Espacos.lg),
            ...corpo,
          ],
        ),
      ),
    );
  }
}

class _FaixaSemTurma extends StatelessWidget {
  const _FaixaSemTurma();

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      decoration: BoxDecoration(
        color: cores.secundariaFixa,
        borderRadius: BorderRadius.circular(Raios.medio),
      ),
      padding: const EdgeInsets.all(Espacos.md),
      child: Text(
        'Entre numa turma para guardar ideias e propor.',
        style: tipografia.corpoMedio.copyWith(color: cores.sobreSecundariaFixa),
      ),
    );
  }
}
