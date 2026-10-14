import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/capa_do_diario.dart';
import '../../api/modelos/turma.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/disco_de_emoji.dart';
import 'paleta.dart';

/// A capa do Diário da turma: sticker, título, frase e os dois contadores, na paleta escolhida. O
/// lápis abre a folha de personalizar, que qualquer membro pode usar.
class CartaoDaCapa extends StatelessWidget {
  const CartaoDaCapa({
    super.key,
    required this.capa,
    required this.turma,
    required this.aoPersonalizar,
  });

  final CapaDoDiario capa;
  final Turma turma;
  final VoidCallback aoPersonalizar;

  // o disco do sticker (82) e a folga até o texto: o título e a frase nunca chegam debaixo dele
  static const _larguraDoSticker = 82.0;
  static const _folgaDoSticker = 12.0;
  static const _alturaDoLapis = 48.0;

  @override
  Widget build(BuildContext context) {
    final tipografia = Tipografia.de(context);
    final paleta = coresDaPaleta(capa.paleta, Cores.de(context));
    final frase = capa.frase;
    final textoDoContador = tipografia.etiquetaMedia.copyWith(
      color: paleta.textoDaCapa,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espacos.cartao),
      decoration: BoxDecoration(
        color: paleta.capa,
        borderRadius: BorderRadius.circular(Raios.grande),
        border: paleta.bordaDaCapa == null
            ? null
            : Border.all(color: paleta.bordaDaCapa!),
        boxShadow: Sombras.nivel1,
      ),
      child: ConstrainedBox(
        // o piso cobre o disco do sticker, a folga e o lápis embaixo dele: com título de uma linha e sem
        // frase, o lápis (canto inferior) cairia sobre o sticker (canto superior)
        constraints: const BoxConstraints(
          minHeight: _larguraDoSticker + _folgaDoSticker + _alturaDoLapis,
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: 8 * math.pi / 180,
                  child: DiscoDeEmoji(
                    emoji: capa.sticker.glifo,
                    tamanho: _larguraDoSticker,
                    cor: paleta.disco,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: _larguraDoSticker + _folgaDoSticker,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capa.tituloPara(turma),
                    style: tipografia.tituloGrande.copyWith(
                      color: paleta.textoDaCapa,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (frase != null) ...[
                    const SizedBox(height: Espacos.sm),
                    Text(
                      frase,
                      style: tipografia.corpoMedio.copyWith(
                        color: paleta.textoDaCapa,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: Espacos.md),
                  Wrap(
                    spacing: Espacos.md,
                    children: [
                      Text(
                        _contador(capa.atividades, 'atividade', 'atividades'),
                        style: textoDoContador,
                      ),
                      Text(
                        _contador(capa.fotos, 'foto', 'fotos'),
                        style: textoDoContador,
                      ),
                    ],
                  ),
                  // reserva a faixa do lápis: o botão fica no canto, sem cobrir o contador
                  const SizedBox(height: 40),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                onPressed: aoPersonalizar,
                tooltip: 'Personalizar o diário',
                icon: Icon(Symbols.edit, color: paleta.textoDaCapa),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _contador(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';
}
