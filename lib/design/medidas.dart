import 'package:flutter/material.dart';

/// Raios do Stitch.
abstract final class Raios {
  static const pequeno = 8.0;
  static const padrao = 16.0;
  static const medio = 24.0;
  static const grande = 32.0;
  static const enorme = 48.0;
}

/// Grade de 4pt e as margens de tela do Stitch.
abstract final class Espacos {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const margemDaTela = 20.0;
  static const cartao = 20.0;
}

/// Sombras do DESIGN.md: tinta espresso (#2B231E) no lugar de preto, e o terracota da marca no
/// nível 2. O alfa já está convertido para o byte do ARGB (0.04 → 0x0A, 0.12 → 0x1F, 0.14 → 0x24).
abstract final class Sombras {
  static const nivel1 = [
    BoxShadow(
      color: Color(0x0A2B231E),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];
  static const nivel2 = [
    BoxShadow(
      color: Color(0x1FD85A38),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x0A2B231E),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];
  static const nivel3 = [
    BoxShadow(
      color: Color(0x242B231E),
      offset: Offset(0, 16),
      blurRadius: 36,
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color(0x0F2B231E),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];
}
