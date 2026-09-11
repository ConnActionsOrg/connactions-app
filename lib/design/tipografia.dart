import 'package:flutter/material.dart';

import 'cores.dart';

/// Escala tipográfica do Stitch, versão mobile. `height` é linha ÷ tamanho e `letterSpacing` é o
/// tracking em `em` convertido para pixels lógicos, que é a unidade do Flutter.
@immutable
class Tipografia extends ThemeExtension<Tipografia> {
  const Tipografia({
    required this.displayGrande,
    required this.tituloGrande,
    required this.tituloMedio,
    required this.tituloPequeno,
    required this.rotuloTitulo,
    required this.corpoGrande,
    required this.corpoMedio,
    required this.corpoPequeno,
    required this.etiquetaGrande,
    required this.etiquetaMedia,
    required this.etiquetaPequena,
  });

  static const familiaTitulos = 'Epilogue';
  static const familiaTexto = 'PlusJakartaSans';

  final TextStyle displayGrande;
  final TextStyle tituloGrande;
  final TextStyle tituloMedio;
  final TextStyle tituloPequeno;
  final TextStyle rotuloTitulo;
  final TextStyle corpoGrande;
  final TextStyle corpoMedio;
  final TextStyle corpoPequeno;
  final TextStyle etiquetaGrande;
  final TextStyle etiquetaMedia;
  final TextStyle etiquetaPequena;

  factory Tipografia.padrao(Cores cores) {
    TextStyle titulo(
      double tamanho,
      double linha,
      FontWeight peso,
      double tracking,
    ) => TextStyle(
      fontFamily: familiaTitulos,
      fontSize: tamanho,
      height: linha / tamanho,
      fontWeight: peso,
      letterSpacing: tracking * tamanho,
      color: cores.sobreSuperficie,
    );
    TextStyle texto(
      double tamanho,
      double linha,
      FontWeight peso, [
      double tracking = 0,
    ]) => TextStyle(
      fontFamily: familiaTexto,
      fontSize: tamanho,
      height: linha / tamanho,
      fontWeight: peso,
      letterSpacing: tracking * tamanho,
      color: cores.sobreSuperficie,
    );
    return Tipografia(
      displayGrande: titulo(30, 38, FontWeight.w700, -0.02),
      tituloGrande: titulo(26, 34, FontWeight.w700, -0.02),
      tituloMedio: titulo(22, 30, FontWeight.w600, -0.01),
      tituloPequeno: titulo(18, 26, FontWeight.w600, 0),
      rotuloTitulo: texto(16, 24, FontWeight.w600),
      corpoGrande: texto(16, 24, FontWeight.w400),
      corpoMedio: texto(14, 22, FontWeight.w400),
      corpoPequeno: texto(13, 18, FontWeight.w400),
      etiquetaGrande: texto(14, 20, FontWeight.w600, 0.01),
      etiquetaMedia: texto(12, 16, FontWeight.w600, 0.02),
      etiquetaPequena: texto(11, 14, FontWeight.w700, 0.04),
    );
  }

  static Tipografia de(BuildContext context) =>
      Theme.of(context).extension<Tipografia>()!;

  @override
  Tipografia copyWith() => this;

  @override
  Tipografia lerp(Tipografia? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
