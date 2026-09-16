import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/turma.dart';
import '../../app/dependencias.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../../design/widgets/pilha_de_avatares.dart';
import '../turmas/convite.dart';
import '../turmas/detalhe_da_turma.dart';
import '../turmas/seletor_de_turma.dart';
import '../turmas/turmas.dart';

/// O Feed é a turma ativa. Sem turmas, convida a criar ou entrar; com turma, diz de quem é a vez e
/// mostra os membros. A atividade aberta chega na fatia 2 e toma o lugar do cartão da vez.
class TelaDoFeed extends ConsumerWidget {
  const TelaDoFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turmas = ref.watch(turmasProvider);
    final ativa = ref.watch(turmaAtivaProvider);
    final lista = turmas.value;
    final erro = turmas.error;
    final Widget corpo;
    if (lista == null && erro != null) {
      corpo = EstadoDeErro(
        mensagem: mensagemDoErro(erro),
        aoTentarDeNovo: () {
          // a falha pode ter nascido no perfil, que Turmas.build espera; invalidar só as turmas releria o mesmo erro
          ref.invalidate(perfilAtualProvider);
          ref.invalidate(turmasProvider);
        },
      );
    } else if (lista == null) {
      corpo = const Center(child: CircularProgressIndicator());
    } else if (ativa == null) {
      corpo = const _SemTurmas();
    } else {
      corpo = _ComTurma(turma: ativa);
    }
    return Scaffold(appBar: const Cabecalho(), body: corpo);
  }
}

class _SemTurmas extends StatelessWidget {
  const _SemTurmas();

  @override
  Widget build(BuildContext context) => EstadoVazio(
    icone: Symbols.local_cafe,
    titulo: 'Nenhuma turma por aqui ainda',
    texto:
        'Crie uma turma para os seus amigos ou entre numa com o código de convite.',
    acao: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: () => context.push('/turmas/nova'),
          icon: const Icon(Symbols.add),
          label: const Text('Criar turma'),
        ),
        const SizedBox(height: Espacos.sm),
        TextButton.icon(
          onPressed: () => context.push('/turmas/entrar'),
          icon: const Icon(Symbols.key),
          label: const Text('Entrar com código'),
        ),
      ],
    ),
  );
}

class _ComTurma extends ConsumerWidget {
  const _ComTurma({required this.turma});

  final Turma turma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final euId = ref.watch(perfilAtualProvider).value?.id;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(turmasProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacos.margemDaTela,
          Espacos.md,
          Espacos.margemDaTela,
          Espacos.xl,
        ),
        children: [
          const SeletorDeTurma(),
          const SizedBox(height: Espacos.md),
          _CartaoDaVez(turma: turma, souEu: turma.vezDe.id == euId),
          const SizedBox(height: Espacos.md),
          _CartaoDosMembros(turma: turma),
        ],
      ),
    );
  }
}

/// Âmbar como o "Vez da rodada" do Stitch. Na fatia 2 vira o cartão da atividade aberta.
class _CartaoDaVez extends StatelessWidget {
  const _CartaoDaVez({required this.turma, required this.souEu});

  final Turma turma;
  final bool souEu;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      decoration: BoxDecoration(
        color: cores.secundariaFixa,
        borderRadius: BorderRadius.circular(Raios.medio),
      ),
      padding: const EdgeInsets.all(Espacos.cartao),
      child: Row(
        children: [
          Avatar(
            nome: turma.vezDe.nome,
            fotoUrl: turma.vezDe.fotoUrl,
            tamanho: 48,
          ),
          const SizedBox(width: Espacos.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  souEu
                      ? 'É a sua vez de propor!'
                      : 'É a vez de ${turma.vezDe.primeiroNome} propor',
                  style: tipografia.tituloPequeno,
                ),
                const SizedBox(height: Espacos.xs),
                Text(
                  'A primeira atividade da turma aparece aqui quando for lançada.',
                  style: tipografia.corpoPequeno.copyWith(
                    color: cores.sobreSecundariaFixa,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoDosMembros extends ConsumerWidget {
  const _CartaoDosMembros({required this.turma});

  final Turma turma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final membros = ref.watch(turmaDetalheProvider(turma.id)).value?.membros;
    return Container(
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.medio),
        boxShadow: Sombras.nivel1,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push('/turmas/${turma.id}'),
          borderRadius: BorderRadius.circular(Raios.medio),
          child: Padding(
            padding: const EdgeInsets.all(Espacos.cartao),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (membros != null) ...[
                      PilhaDeAvatares(
                        pessoas: [for (final m in membros) m.pessoa],
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        turma.membrosPorExtenso,
                        style: tipografia.rotuloTitulo,
                      ),
                    ),
                    Icon(
                      Symbols.chevron_right,
                      color: cores.sobreSuperficieVariante,
                    ),
                  ],
                ),
                const SizedBox(height: Espacos.md),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(compartilhadorProvider)
                      .compartilhar(textoDoConvite(turma)),
                  icon: const Icon(Symbols.share),
                  label: const Text('Convidar amigos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
