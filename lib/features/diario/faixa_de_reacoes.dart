import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/capa_do_diario.dart';
import '../../api/modelos/reacao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import 'folha_de_reacoes.dart';
import 'paleta.dart';

/// A faixa de baixo do cartão do Diário: um chip por reação que alguém deixou (o meu fica nas cores
/// da paleta), o "＋" que abre os seis tipos e o botão dos comentários.
class FaixaDeReacoes extends StatelessWidget {
  const FaixaDeReacoes({
    super.key,
    required this.reacoes,
    required this.totalDeComentarios,
    required this.paleta,
    required this.aoReagir,
    required this.aoAbrirComentarios,
  });

  final List<Reacao> reacoes;
  final int totalDeComentarios;
  final PaletaDoDiario paleta;
  final ValueChanged<TipoDeReacao> aoReagir;
  final VoidCallback aoAbrirComentarios;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Wrap(
          spacing: Espacos.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final r in reacoes)
              _ChipDeReacao(
                reacao: r,
                paleta: paleta,
                aoTocar: () => aoReagir(r.tipo),
              ),
            _ChipMais(
              aoTocar: () => mostrarFolhaDeReacoes(
                context,
                reacoes: reacoes,
                aoReagir: aoReagir,
              ),
            ),
          ],
        ),
      ),
      _BotaoDeComentarios(
        total: totalDeComentarios,
        aoTocar: aoAbrirComentarios,
      ),
    ],
  );
}

/// O alvo de toque tem 48 dp mesmo com o chip menor por dentro.
const _alvo = BoxConstraints(minHeight: 48, minWidth: 48);

/// "Coração, 2 reações, marcada": o que o leitor de tela diz e o que a dica do chip mostra.
String rotuloDaReacao(Reacao r) =>
    '${r.tipo.rotulo}, ${r.total} ${r.total == 1 ? 'reação' : 'reações'}'
    '${r.minha ? ', marcada' : ''}';

class _ChipDeReacao extends StatelessWidget {
  const _ChipDeReacao({
    required this.reacao,
    required this.paleta,
    required this.aoTocar,
  });

  final Reacao reacao;
  final PaletaDoDiario paleta;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final pintura = coresDaPaleta(paleta, cores);
    final minha = reacao.minha;
    final rotulo = rotuloDaReacao(reacao);
    return Tooltip(
      message: rotulo,
      child: Semantics(
        button: true,
        selected: minha,
        label: rotulo,
        excludeSemantics: true,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: _alvo,
            child: Center(
              widthFactor: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: minha ? pintura.chipFundo : cores.superficieMaisBaixa,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: minha ? pintura.chipBorda : cores.contornoVariante,
                  ),
                ),
                child: Text(
                  '${reacao.tipo.glifo} ${reacao.total}',
                  style: tipografia.etiquetaMedia.copyWith(
                    color: minha ? pintura.chipTexto : cores.sobreSuperficie,
                    fontWeight: minha ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipMais extends StatelessWidget {
  const _ChipMais({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Tooltip(
      message: 'Reagir',
      child: Semantics(
        button: true,
        label: 'Reagir',
        excludeSemantics: true,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: _alvo,
            child: Center(
              widthFactor: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cores.contornoVariante),
                ),
                child: Icon(
                  Symbols.add,
                  size: 20,
                  color: cores.sobreSuperficieVariante,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoDeComentarios extends StatelessWidget {
  const _BotaoDeComentarios({required this.total, required this.aoTocar});

  final int total;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final rotulo = switch (total) {
      0 => 'Comentar',
      1 => '1 comentário',
      _ => '$total comentários',
    };
    return Tooltip(
      message: rotulo,
      child: Semantics(
        button: true,
        label: rotulo,
        excludeSemantics: true,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: _alvo,
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Espacos.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.chat_bubble,
                      size: 20,
                      color: cores.sobreSuperficieVariante,
                    ),
                    const SizedBox(width: Espacos.xs),
                    Text(
                      '$total',
                      style: tipografia.etiquetaMedia.copyWith(
                        color: cores.sobreSuperficieVariante,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
