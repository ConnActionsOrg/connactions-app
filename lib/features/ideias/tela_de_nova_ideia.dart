import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/mensagens.dart';
import '../../design/medidas.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import 'ideias.dart';

/// Anotar uma ideia é coisa rápida: só nome e descrição. Formato e regras se decidem no Propor.
class TelaDeNovaIdeia extends ConsumerStatefulWidget {
  const TelaDeNovaIdeia({super.key, required this.turmaId});

  final String turmaId;

  @override
  ConsumerState<TelaDeNovaIdeia> createState() => _TelaDeNovaIdeiaState();
}

class _TelaDeNovaIdeiaState extends ConsumerState<TelaDeNovaIdeia> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  bool get _podeGuardar => !_guardando && _titulo.text.trim().isNotEmpty;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    // capturado antes de navegar: o aviso aparece no backlog, não nesta tela que vai fechar
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(ideiasProvider(widget.turmaId).notifier)
          .criar(
            titulo: _titulo.text.trim(),
            descricao: _descricao.text.trim(),
          );
      if (!mounted) return;
      context.pop();
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Ideia guardada')));
    } catch (e) {
      // o 409 de backlog cheio e o 422 já vêm com a mensagem pronta; o rascunho fica na tela
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // a escrita lê o notifier: sem ouvinte, a família autoDispose morreria no meio da chamada
    ref.watch(ideiasProvider(widget.turmaId));
    return Scaffold(
      appBar: const Cabecalho(titulo: 'Nova ideia'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacos.margemDaTela,
          Espacos.md,
          Espacos.margemDaTela,
          Espacos.xl,
        ),
        children: [
          TextField(
            controller: _titulo,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome da ideia',
              hintText: 'Noite de pizza',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Espacos.md),
          TextField(
            controller: _descricao,
            maxLength: 1000,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Como seria?',
              hintText: 'Cada um traz um recheio...',
            ),
          ),
          const SizedBox(height: Espacos.xl),
          FilledButton(
            onPressed: _podeGuardar ? _guardar : null,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar ideia'),
          ),
        ],
      ),
    );
  }
}
