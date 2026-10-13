import 'package:flutter/material.dart';

import '../../api/mensagens.dart';
import 'aviso.dart';

/// "Carregar mais" das listas paginadas. `aoCarregar` não se protege de chamadas concorrentes: o
/// botão fica desabilitado, com progresso no lugar do texto, até a resposta voltar. A falha vira
/// aviso e o botão volta.
class BotaoCarregarMais extends StatefulWidget {
  const BotaoCarregarMais({super.key, required this.aoCarregar});

  final Future<void> Function() aoCarregar;

  @override
  State<BotaoCarregarMais> createState() => _BotaoCarregarMaisState();
}

class _BotaoCarregarMaisState extends State<BotaoCarregarMais> {
  bool _carregando = false;

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      await widget.aoCarregar();
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: _carregando ? null : _carregar,
    child: _carregando
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('Carregar mais'),
  );
}
