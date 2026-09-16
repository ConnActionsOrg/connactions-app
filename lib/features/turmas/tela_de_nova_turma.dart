import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/mensagens.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/disco_de_emoji.dart';
import 'emojis_de_turma.dart';
import 'turmas.dart';

/// Nome e emoji. Ao criar, a turma já nasce ativa e a tela volta ao Feed.
class TelaDeNovaTurma extends ConsumerStatefulWidget {
  const TelaDeNovaTurma({super.key});

  @override
  ConsumerState<TelaDeNovaTurma> createState() => _TelaDeNovaTurmaState();
}

class _TelaDeNovaTurmaState extends ConsumerState<TelaDeNovaTurma> {
  final _nome = TextEditingController();
  String _emoji = emojisDeTurma.first;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  bool get _podeCriar => _nome.text.trim().isNotEmpty && !_salvando;

  Future<void> _criar() async {
    setState(() => _salvando = true);
    try {
      await ref
          .read(turmasProvider.notifier)
          .criar(nome: _nome.text.trim(), emoji: _emoji);
      if (mounted) context.go('/feed');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipografia = Tipografia.de(context);
    return Scaffold(
      appBar: const Cabecalho(titulo: 'Nova turma'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacos.margemDaTela,
          Espacos.md,
          Espacos.margemDaTela,
          Espacos.xl,
        ),
        children: [
          TextField(
            controller: _nome,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome da turma',
              hintText: 'Turma do Domingo',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Espacos.lg),
          Text('Escolha um emoji', style: tipografia.rotuloTitulo),
          const SizedBox(height: Espacos.sm),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final emoji in emojisDeTurma)
                _OpcaoDeEmoji(
                  emoji: emoji,
                  selecionado: emoji == _emoji,
                  aoTocar: () => setState(() => _emoji = emoji),
                ),
            ],
          ),
          const SizedBox(height: Espacos.xl),
          FilledButton(
            onPressed: _podeCriar ? _criar : null,
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Criar turma'),
          ),
        ],
      ),
    );
  }
}

class _OpcaoDeEmoji extends StatelessWidget {
  const _OpcaoDeEmoji({
    required this.emoji,
    required this.selecionado,
    required this.aoTocar,
  });

  final String emoji;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Semantics(
      button: true,
      selected: selecionado,
      label: 'Emoji $emoji',
      child: InkWell(
        onTap: aoTocar,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selecionado ? cores.primaria : Colors.transparent,
              width: 2,
            ),
          ),
          child: DiscoDeEmoji(emoji: emoji, tamanho: 48),
        ),
      ),
    );
  }
}
