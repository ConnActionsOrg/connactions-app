import 'package:flutter/material.dart';

import '../../api/modelos/reacao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';

/// Abre a folha dos seis tipos. Escolher um fecha a folha e chama [aoReagir]: o mesmo toque marca ou
/// desmarca, conforme o estado do cartão.
Future<void> mostrarFolhaDeReacoes(
  BuildContext context, {
  required List<Reacao> reacoes,
  required ValueChanged<TipoDeReacao> aoReagir,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  builder: (folha) => FolhaDeReacoes(
    reacoes: reacoes,
    aoEscolher: (tipo) {
      Navigator.of(folha).pop();
      aoReagir(tipo);
    },
  ),
);

class FolhaDeReacoes extends StatelessWidget {
  const FolhaDeReacoes({
    super.key,
    required this.reacoes,
    required this.aoEscolher,
  });

  final List<Reacao> reacoes;
  final ValueChanged<TipoDeReacao> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacos.margemDaTela,
        0,
        Espacos.margemDaTela,
        Espacos.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reagir', style: tipografia.tituloMedio),
          const SizedBox(height: Espacos.md),
          Wrap(
            spacing: Espacos.sm,
            runSpacing: Espacos.sm,
            children: [
              for (final tipo in TipoDeReacao.values)
                _BotaoDeReacao(
                  tipo: tipo,
                  marcada: reacoes.any((r) => r.tipo == tipo && r.minha),
                  aoTocar: () => aoEscolher(tipo),
                  cores: cores,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotaoDeReacao extends StatelessWidget {
  const _BotaoDeReacao({
    required this.tipo,
    required this.marcada,
    required this.aoTocar,
    required this.cores,
  });

  final TipoDeReacao tipo;
  final bool marcada;
  final VoidCallback aoTocar;
  final Cores cores;

  @override
  Widget build(BuildContext context) {
    final rotulo = marcada ? '${tipo.rotulo}, marcada' : tipo.rotulo;
    return Tooltip(
      message: rotulo,
      child: Semantics(
        button: true,
        selected: marcada,
        label: rotulo,
        excludeSemantics: true,
        child: InkResponse(
          onTap: aoTocar,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Raios.padrao),
              color: marcada
                  ? cores.superficieMaisBaixa
                  : cores.superficieContainer,
              border: Border.all(
                width: marcada ? 3 : 1,
                color: marcada ? cores.sobreSuperficie : cores.contornoVariante,
              ),
            ),
            child: Text(tipo.glifo, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}
