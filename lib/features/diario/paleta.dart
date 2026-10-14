import 'package:flutter/material.dart';

import '../../api/modelos/capa_do_diario.dart';
import '../../design/cores.dart';

/// O que uma paleta pinta: a capa do Diário (fundo, texto e disco do sticker) e o chip da reação que
/// a pessoa marcou. Tudo sai de [Cores], sem hexadecimal novo.
class CoresDaPaleta {
  const CoresDaPaleta({
    required this.capa,
    required this.textoDaCapa,
    required this.disco,
    required this.chipFundo,
    required this.chipBorda,
    required this.chipTexto,
    this.bordaDaCapa,
  });

  final Color capa;
  final Color textoDaCapa;
  final Color disco;
  final Color chipFundo;
  final Color chipBorda;
  final Color chipTexto;

  /// Só a Areia, que é clara como o fundo da tela, precisa de contorno.
  final Color? bordaDaCapa;
}

CoresDaPaleta coresDaPaleta(PaletaDoDiario paleta, Cores c) => switch (paleta) {
  PaletaDoDiario.terracota => CoresDaPaleta(
    capa: c.primaria,
    textoDaCapa: c.sobrePrimaria,
    disco: c.primariaFixa,
    chipFundo: c.primariaFixa,
    chipBorda: c.primaria,
    chipTexto: c.sobrePrimariaFixa,
  ),
  PaletaDoDiario.ambar => CoresDaPaleta(
    capa: c.secundariaContainer,
    textoDaCapa: c.sobreSecundariaFixa,
    disco: c.secundariaFixa,
    chipFundo: c.secundariaFixa,
    chipBorda: c.secundaria,
    chipTexto: c.sobreSecundariaFixa,
  ),
  PaletaDoDiario.salvia => CoresDaPaleta(
    capa: c.terciaria,
    textoDaCapa: c.sobrePrimaria,
    disco: c.terciariaFixa,
    chipFundo: c.terciariaFixa,
    chipBorda: c.terciaria,
    chipTexto: c.sobreSuperficie,
  ),
  PaletaDoDiario.areia => CoresDaPaleta(
    capa: c.superficieAlta,
    textoDaCapa: c.sobreSuperficie,
    disco: c.superficieMaisBaixa,
    chipFundo: c.superficieContainer,
    chipBorda: c.sobreSuperficieVariante,
    chipTexto: c.sobreSuperficie,
    bordaDaCapa: c.contornoVariante,
  ),
};
