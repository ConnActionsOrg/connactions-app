import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import 'codigo_de_convite.dart';
import 'turmas.dart';

/// Código de oito letras. Código que a API não conhece vira erro no campo, não aviso.
class TelaDeEntrarNaTurma extends ConsumerStatefulWidget {
  const TelaDeEntrarNaTurma({super.key});

  @override
  ConsumerState<TelaDeEntrarNaTurma> createState() =>
      _TelaDeEntrarNaTurmaState();
}

class _TelaDeEntrarNaTurmaState extends ConsumerState<TelaDeEntrarNaTurma> {
  final _codigo = TextEditingController();
  String? _erro;
  bool _entrando = false;

  @override
  void initState() {
    super.initState();
    // Aquece turmasProvider ao abrir a tela: lido pela 1ª vez só em _entrar(), o build() dele
    // (que chama listarTurmas) corre em paralelo com entrarNaTurma() e termina depois na prática.
    ref.read(turmasProvider);
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  bool get _podeEntrar => codigoCompleto(_codigo.text) && !_entrando;

  Future<void> _entrar() async {
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      await ref.read(turmasProvider.notifier).entrar(_codigo.text);
      if (mounted) context.go('/feed');
    } on ErroDaApi catch (e) {
      if (!mounted) return;
      if (e.codigoInvalido) {
        setState(() => _erro = e.mensagem);
      } else {
        mostrarAviso(context, e.mensagem);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Scaffold(
      appBar: const Cabecalho(titulo: 'Entrar com código'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacos.margemDaTela,
          Espacos.md,
          Espacos.margemDaTela,
          Espacos.xl,
        ),
        children: [
          Text(
            'Peça o código de convite para alguém da turma.',
            style: tipografia.corpoMedio.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          const SizedBox(height: Espacos.lg),
          TextField(
            controller: _codigo,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FormatadorDeCodigo()],
            style: tipografia.tituloPequeno.copyWith(letterSpacing: 3),
            decoration: InputDecoration(
              labelText: 'Código de convite',
              hintText: 'ABCD2345',
              errorText: _erro,
            ),
            onChanged: (_) => setState(() => _erro = null),
          ),
          const SizedBox(height: Espacos.xl),
          FilledButton(
            onPressed: _podeEntrar ? _entrar : null,
            child: _entrando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Entrar na turma'),
          ),
        ],
      ),
    );
  }
}
