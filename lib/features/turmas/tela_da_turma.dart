import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/turma.dart';
import '../../app/dependencias.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/disco_de_emoji.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../../design/widgets/etiqueta.dart';
import '../atividades/atividade_aberta.dart';
import 'convite.dart';
import 'detalhe_da_turma.dart';
import 'turmas.dart';

/// A turma: convite, membros por ordem e a saída. O resumo e o código vêm da lista (um lugar só
/// para regenerar atualizar); só os membros vêm do detalhe.
class TelaDaTurma extends ConsumerWidget {
  const TelaDaTurma({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turmas = ref.watch(turmasProvider);
    final turma = turmas.value?.where((t) => t.id == id).firstOrNull;
    if (turma == null) {
      return turmas.isLoading && !turmas.hasValue
          ? const Scaffold(
              appBar: Cabecalho(titulo: 'Turma'),
              body: Center(child: CircularProgressIndicator()),
            )
          : const _ForaDaTurma();
    }
    final detalhe = ref.watch(turmaDetalheProvider(id));
    final erro = detalhe.error;
    if (erro is ErroDaApi && (erro.semAcesso || erro.naoEncontrado)) {
      return const _ForaDaTurma();
    }
    final aberta = ref.watch(atividadeAbertaProvider(id));
    final euId = ref.watch(perfilAtualProvider).value?.id;
    return Scaffold(
      appBar: Cabecalho(titulo: '${turma.emoji} ${turma.nome}'),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            ref.invalidate(turmaDetalheProvider(id));
            await ref.read(turmaDetalheProvider(id).future);
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
            _Cabeca(turma: turma),
            const SizedBox(height: Espacos.lg),
            _CartaoDoConvite(turma: turma),
            const SizedBox(height: Espacos.lg),
            _Membros(
              turma: turma,
              turmaId: id,
              detalhe: detalhe,
              // enquanto não se sabe se há atividade aberta, trava
              travado: !aberta.hasValue || aberta.value != null,
              aoTentarDeNovo: () => ref.invalidate(turmaDetalheProvider(id)),
            ),
            const SizedBox(height: Espacos.xl),
            _BotaoSair(
              turma: turma,
              membros: detalhe.value?.membros,
              euId: euId,
            ),
          ],
        ),
      ),
    );
  }
}

/// Saí, ou a turma sumiu (403/404): nada mais a mostrar além do caminho de volta.
class _ForaDaTurma extends StatelessWidget {
  const _ForaDaTurma();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const Cabecalho(titulo: 'Turma'),
    body: EstadoVazio(
      icone: Symbols.group_off,
      titulo: 'Você não está mais nesta turma.',
      texto: 'Ela saiu da sua lista.',
      acao: OutlinedButton(
        onPressed: () => context.go('/feed'),
        child: const Text('Voltar'),
      ),
    ),
  );
}

class _Cabeca extends StatelessWidget {
  const _Cabeca({required this.turma});

  final Turma turma;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Column(
      children: [
        DiscoDeEmoji(emoji: turma.emoji, tamanho: 72),
        const SizedBox(height: 12),
        Text(
          turma.nome,
          style: tipografia.tituloGrande,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          turma.membrosPorExtenso,
          style: tipografia.corpoMedio.copyWith(
            color: cores.sobreSuperficieVariante,
          ),
        ),
      ],
    );
  }
}

class _CartaoDoConvite extends ConsumerWidget {
  const _CartaoDoConvite({required this.turma});

  final Turma turma;

  Future<void> _copiar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: turma.codigoConvite));
    if (context.mounted) mostrarAviso(context, 'Código copiado');
  }

  Future<void> _gerarNovo(BuildContext context, WidgetRef ref) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Gerar novo código?'),
        content: const Text(
          'O código atual deixa de funcionar. Quem ainda não entrou vai precisar do novo.',
        ),
        // TextButton nos dois: o FilledButton do tema tem largura mínima infinita e não cabe na
        // barra de ações do diálogo.
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    try {
      await ref.read(turmasProvider.notifier).regenerarConvite(turma.id);
      if (context.mounted) mostrarAviso(context, 'Novo código gerado');
    } catch (e) {
      if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            'Código de convite',
            style: tipografia.etiquetaMedia.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          const SizedBox(height: Espacos.xs),
          Row(
            children: [
              Text(
                turma.codigoConvite,
                style: tipografia.tituloPequeno.copyWith(letterSpacing: 3),
              ),
              IconButton(
                onPressed: () => _copiar(context),
                tooltip: 'Copiar código',
                icon: Icon(
                  Symbols.content_copy,
                  color: cores.sobreSuperficieVariante,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacos.xs),
          Text(
            'Quem digitar este código entra na turma.',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          const SizedBox(height: Espacos.md),
          FilledButton.icon(
            onPressed: () => ref
                .read(compartilhadorProvider)
                .compartilhar(textoDoConvite(turma)),
            icon: const Icon(Symbols.share),
            label: const Text('Compartilhar convite'),
          ),
          TextButton(
            onPressed: () => _gerarNovo(context, ref),
            child: const Text('Gerar novo código'),
          ),
        ],
      ),
    );
  }
}

class _Membros extends StatelessWidget {
  const _Membros({
    required this.turma,
    required this.turmaId,
    required this.detalhe,
    required this.travado,
    required this.aoTentarDeNovo,
  });

  final Turma turma;
  final String turmaId;
  final AsyncValue<TurmaDetalhe> detalhe;
  final bool travado;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final tipografia = Tipografia.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Membros (${turma.totalDeMembros})',
          style: tipografia.tituloPequeno,
        ),
        const SizedBox(height: Espacos.sm),
        switch (detalhe) {
          AsyncData(:final value) => Column(
            children: [
              for (final membro in value.membros)
                _LinhaDeMembro(membro: membro, turma: turma),
            ],
          ),
          AsyncError(:final error) => EstadoDeErro(
            mensagem: mensagemDoErro(error),
            aoTentarDeNovo: aoTentarDeNovo,
          ),
          _ => const Padding(
            padding: EdgeInsets.all(Espacos.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
        const SizedBox(height: Espacos.md),
        _BotaoEmbaralhar(turmaId: turmaId, travado: travado),
      ],
    );
  }
}

class _LinhaDeMembro extends StatelessWidget {
  const _LinhaDeMembro({required this.membro, required this.turma});

  final Membro membro;
  final Turma turma;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final pessoa = membro.pessoa;
    final criou = pessoa.id == turma.criadorId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacos.sm),
      child: Row(
        children: [
          Avatar(nome: pessoa.nome, fotoUrl: pessoa.fotoUrl, tamanho: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pessoa.nome, style: tipografia.rotuloTitulo),
                Text(
                  criou
                      ? '@${pessoa.handle} · criou a turma'
                      : '@${pessoa.handle}',
                  style: tipografia.corpoPequeno.copyWith(
                    color: cores.sobreSuperficieVariante,
                  ),
                ),
              ],
            ),
          ),
          if (pessoa.id == turma.vezDe.id)
            const Etiqueta(texto: 'Vez', tom: TomDaEtiqueta.ambar),
        ],
      ),
    );
  }
}

/// Qualquer membro embaralha; embaralhar de novo desfaz, então não há confirmação. Com atividade
/// aberta a ordem está travada (a API recusaria com ordem_travada).
class _BotaoEmbaralhar extends ConsumerWidget {
  const _BotaoEmbaralhar({required this.turmaId, required this.travado});

  final String turmaId;
  final bool travado;

  Future<void> _embaralhar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(turmaDetalheProvider(turmaId).notifier).embaralhar();
      if (context.mounted) mostrarAviso(context, 'Ordem embaralhada');
    } on ErroDaApi catch (e) {
      if (!context.mounted) return;
      mostrarAviso(context, e.mensagem);
      if (e.conflito) invalidarRodada(ref.invalidate, turmaId);
    } catch (e) {
      if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: travado ? null : () => _embaralhar(context, ref),
          icon: const Icon(Symbols.shuffle),
          label: const Text('Embaralhar a ordem'),
        ),
        if (travado) ...[
          const SizedBox(height: Espacos.xs),
          Text(
            'Com uma atividade aberta, a ordem fica travada.',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _BotaoSair extends ConsumerWidget {
  const _BotaoSair({
    required this.turma,
    required this.membros,
    required this.euId,
  });

  final Turma turma;
  final List<Membro>? membros;
  final String? euId;

  /// Com os membros ainda não carregados, fica o texto genérico.
  String get _consequencia {
    final total = membros?.length;
    if (total == 1) return 'Você é a última pessoa: sair apaga a turma.';
    if (total != null && turma.vezDe.id == euId) {
      return 'A vez passa para a próxima pessoa da ordem.';
    }
    return 'Você pode voltar com um novo convite.';
  }

  Future<void> _sair(BuildContext context, WidgetRef ref) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Sair da turma?'),
        content: Text(_consequencia),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    // capturado antes de navegar: o aviso aparece já no Feed, não nesta tela que vai fechar
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await ref.read(turmasProvider.notifier).sair(turma.id);
      if (!context.mounted) return;
      context.go('/feed');
      mensageiro.showSnackBar(
        SnackBar(content: Text('Você saiu de ${turma.nome}')),
      );
    } catch (e) {
      if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    // estilo explícito: o OutlinedButton do tema é neutro, e este é destrutivo
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(foregroundColor: cores.erro),
      onPressed: () => _sair(context, ref),
      icon: const Icon(Symbols.logout),
      label: const Text('Sair da turma'),
    );
  }
}
