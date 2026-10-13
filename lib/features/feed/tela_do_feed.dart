import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/atividade.dart';
import '../../api/modelos/turma.dart';
import '../../app/dependencias.dart';
import '../../app/relogio.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../../design/widgets/etiqueta.dart';
import '../../design/widgets/pilha_de_avatares.dart';
import '../atividades/atividade_aberta.dart';
import '../atividades/cartao_da_atividade.dart';
import '../atividades/cartao_de_registro.dart';
import '../atividades/foto_para_ver.dart';
import '../atividades/tela_de_novo_registro.dart';
import '../atividades/tempo.dart';
import '../atividades/visualizador_de_fotos.dart';
import '../notificacoes/cartao_de_permissao.dart';
import '../turmas/convite.dart';
import '../turmas/detalhe_da_turma.dart';
import '../turmas/seletor_de_turma.dart';
import '../turmas/turmas.dart';

/// O Feed é a turma ativa. Sem turmas, convida a criar ou entrar; com turma e sem atividade, diz de
/// quem é a vez; com atividade aberta, mostra a rodada, os registros e a ação de quem está olhando.
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
    final aberta = ref.watch(atividadeAbertaProvider(turma.id));
    final agora = ref.watch(relogioProvider)();
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await Future.wait<Object?>([
            ref.refresh(turmasProvider.future),
            ref.refresh(atividadeAbertaProvider(turma.id).future),
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
          const SeletorDeTurma(),
          const SizedBox(height: Espacos.md),
          // só aqui, com turma: antes da primeira não há vez de ninguém para avisar
          const CartaoDePermissao(),
          ..._miolo(ref, aberta, euId, agora),
          const SizedBox(height: Espacos.md),
          _CartaoDosMembros(turma: turma),
        ],
      ),
    );
  }

  List<Widget> _miolo(
    WidgetRef ref,
    AsyncValue<Atividade?> aberta,
    String? euId,
    DateTime agora,
  ) {
    final atividade = aberta.value;
    final erro = aberta.error;
    // Só a 1ª carga que falhou vira tela de erro: numa recarga que falha o valor anterior (até o
    // "sem atividade") segue na tela, e o aviso já saiu pelo onRefresh.
    if (erro != null && !aberta.hasValue) {
      return [
        EstadoDeErro(
          mensagem: mensagemDoErro(erro),
          aoTentarDeNovo: () =>
              ref.invalidate(atividadeAbertaProvider(turma.id)),
        ),
      ];
    }
    if (atividade == null) {
      return [
        _CartaoDaVez(
          turma: turma,
          souEu: turma.vezDe.id == euId,
          // recarga com o valor já na tela (puxar para baixo) não esconde o botão de propor
          carregando: aberta.isLoading && !aberta.hasValue,
        ),
      ];
    }
    final souProponente = atividade.proponente.id == euId;
    return [
      _FaixaDoProponente(
        atividade: atividade,
        souEu: souProponente,
        agora: agora,
      ),
      const SizedBox(height: Espacos.md),
      CartaoDaAtividade(
        atividade: atividade,
        agora: agora,
        rodape: souProponente ? _BotaoEncerrar(turmaId: turma.id) : null,
      ),
      const SizedBox(height: Espacos.lg),
      _Registros(atividade: atividade, euId: euId, agora: agora),
      const SizedBox(height: Espacos.md),
      _AcaoDeRegistro(atividade: atividade, euId: euId),
    ];
  }
}

/// Âmbar como o "Vez da rodada" do Stitch. Sem atividade aberta: quem está na vez e, se sou eu, o
/// botão de propor.
class _CartaoDaVez extends StatelessWidget {
  const _CartaoDaVez({
    required this.turma,
    required this.souEu,
    required this.carregando,
  });

  final Turma turma;
  final bool souEu;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final Widget segundaLinha = carregando
        ? const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(minHeight: 2),
          )
        : Text(
            souEu
                ? 'Lance a próxima atividade da turma.'
                : 'Quando ${turma.vezDe.primeiroNome} lançar, a atividade aparece aqui.',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSecundariaFixa,
            ),
          );
    return Container(
      decoration: BoxDecoration(
        color: cores.secundariaFixa,
        borderRadius: BorderRadius.circular(Raios.medio),
      ),
      padding: const EdgeInsets.all(Espacos.cartao),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    segundaLinha,
                  ],
                ),
              ),
            ],
          ),
          if (souEu && !carregando) ...[
            const SizedBox(height: Espacos.md),
            FilledButton.icon(
              onPressed: () => context.push('/turmas/${turma.id}/propor'),
              icon: const Icon(Symbols.add),
              label: const Text('Propor atividade'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quem propôs e há quanto tempo, na mesma faixa âmbar.
class _FaixaDoProponente extends StatelessWidget {
  const _FaixaDoProponente({
    required this.atividade,
    required this.souEu,
    required this.agora,
  });

  final Atividade atividade;
  final bool souEu;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final quem = souEu ? 'Você' : atividade.proponente.primeiroNome;
    return Container(
      decoration: BoxDecoration(
        color: cores.secundariaFixa,
        borderRadius: BorderRadius.circular(Raios.medio),
      ),
      padding: const EdgeInsets.all(Espacos.md),
      child: Row(
        children: [
          Avatar(
            nome: atividade.proponente.nome,
            fotoUrl: atividade.proponente.fotoUrl,
            tamanho: 48,
          ),
          const SizedBox(width: Espacos.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$quem propôs a rodada ${atividade.numero}',
                  style: tipografia.tituloPequeno,
                ),
                const SizedBox(height: 2),
                Text(
                  haQuantoTempo(atividade.lancadaEm, agora),
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

/// "Quem já fez até agora": contagem e a fileira de miniaturas; tocar abre o visualizador.
class _Registros extends ConsumerWidget {
  const _Registros({
    required this.atividade,
    required this.euId,
    required this.agora,
  });

  final Atividade atividade;
  final String? euId;
  final DateTime agora;

  /// O 409 (a atividade foi encerrada em outro aparelho) segue para o visualizador, que fecha e
  /// avisa. A rodada só é relida quando ele fecha: coberto por ele, o Feed está com o ouvinte pausado.
  Future<void> _apagar(WidgetRef ref, String registroId) async {
    final aberta = atividadeAbertaProvider(atividade.turmaId);
    try {
      await ref.read(aberta.notifier).apagarRegistro(registroId);
    } on ErroDaApi catch (e) {
      if (e.conflito && ref.context.mounted) {
        invalidarRodada(ref.invalidate, atividade.turmaId);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final registros = atividade.registros;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quem já fez até agora',
                style: tipografia.tituloPequeno,
              ),
            ),
            if (registros.isEmpty)
              Text(
                'Ninguém ainda',
                style: tipografia.corpoPequeno.copyWith(
                  color: cores.sobreSuperficieVariante,
                ),
              )
            else
              Etiqueta(
                texto: registros.length == 1
                    ? '1 postado'
                    : '${registros.length} postados',
              ),
          ],
        ),
        if (registros.isNotEmpty) ...[
          const SizedBox(height: Espacos.md),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: registros.length,
              separatorBuilder: (_, _) => const SizedBox(width: Espacos.sm),
              itemBuilder: (_, i) => CartaoDeRegistro(
                registro: registros[i],
                meu: registros[i].autor.id == euId,
                aoTocar: () => mostrarVisualizadorDeFotos(
                  context,
                  fotos: [for (final r in registros) FotoParaVer.doRegistro(r)],
                  indiceInicial: i,
                  agora: agora,
                  podeApagar: (f) => f.autor?.id == euId && atividade.aberta,
                  aoApagar: (f) => _apagar(ref, f.id!),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// O que quem está olhando pode fazer, pelas regras de formato; e o consentimento da pública.
class _AcaoDeRegistro extends ConsumerWidget {
  const _AcaoDeRegistro({required this.atividade, required this.euId});

  final Atividade atividade;
  final String? euId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final id = euId;
    final meu = id == null ? null : atividade.registroDe(id);
    final souProponente = atividade.proponente.id == euId;
    final total = atividade.registros.length;

    Widget linha(String texto) => Text(
      texto,
      style: tipografia.corpoPequeno.copyWith(
        color: cores.sobreSuperficieVariante,
      ),
      textAlign: TextAlign.center,
    );
    Widget botao(String rotulo) => OutlinedButton.icon(
      onPressed: () =>
          abrirNovoRegistro(context, ref, turmaId: atividade.turmaId),
      icon: const Icon(Symbols.photo_camera),
      label: Text(rotulo),
    );

    final acao = switch (atividade.formato) {
      FormatoDeAtividade.individual =>
        meu == null
            ? botao('Adicionar meu registro')
            : linha('Você já postou o seu registro.'),
      FormatoDeAtividade.grupo when !souProponente => linha(
        'Só quem propôs posta as fotos desta atividade.',
      ),
      FormatoDeAtividade.grupo when total >= 10 => linha(
        'Esta atividade já tem as 10 fotos.',
      ),
      FormatoDeAtividade.grupo => botao('Adicionar foto ($total/10)'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        acao,
        if (atividade.publica) ...[
          const SizedBox(height: Espacos.sm),
          // decidido no lançamento e dito antes de alguém postar: é o consentimento da Comunidade
          linha('As fotos desta atividade ficam visíveis na Comunidade.'),
        ],
      ],
    );
  }
}

/// Só o proponente vê. Confirma, encerra, e o Feed volta ao cartão da vez com o nome novo.
class _BotaoEncerrar extends ConsumerWidget {
  const _BotaoEncerrar({required this.turmaId});

  final String turmaId;

  Future<void> _encerrar(BuildContext context, WidgetRef ref) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Encerrar atividade?'),
        content: const Text(
          'Ela vai para o Diário e a vez passa para a próxima pessoa da ordem. '
          'Quem ainda não postou não vai mais poder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    final euId = ref.read(perfilAtualProvider).value?.id;
    try {
      final encerramento = await ref
          .read(atividadeAbertaProvider(turmaId).notifier)
          .encerrar();
      if (!context.mounted) return;
      final proxima = encerramento.turma.vezDe;
      mostrarAviso(
        context,
        proxima.id == euId
            ? 'Atividade encerrada. Agora é a sua vez!'
            : 'Atividade encerrada. Agora é a vez de ${proxima.primeiroNome}.',
      );
    } on ErroDaApi catch (e) {
      if (!context.mounted) return;
      mostrarAviso(context, e.mensagem);
      if (e.conflito) invalidarRodada(ref.invalidate, turmaId);
    } catch (e) {
      if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () => _encerrar(context, ref),
      icon: const Icon(Symbols.flag),
      label: const Text('Encerrar atividade'),
    ),
  );
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
