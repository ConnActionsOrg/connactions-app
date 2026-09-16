import 'package:flutter/material.dart';

import '../cores.dart';
import '../tipografia.dart';

/// Os três tons dos chips do DESIGN.md: terracota (destaque), âmbar (a vez, o que vem), sálvia
/// (concluído).
enum TomDaEtiqueta { terracota, ambar, salvia }

/// Chip pill só de leitura.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    this.tom = TomDaEtiqueta.terracota,
  });

  final String texto;
  final TomDaEtiqueta tom;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final (fundo, cor) = switch (tom) {
      TomDaEtiqueta.terracota => (
        cores.primariaFixa,
        cores.sobrePrimariaFixaVariante,
      ),
      TomDaEtiqueta.ambar => (cores.secundariaFixa, cores.sobreSecundariaFixa),
      TomDaEtiqueta.salvia => (cores.terciariaFixa, cores.terciaria),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto, style: tipografia.etiquetaMedia.copyWith(color: cor)),
    );
  }
}
