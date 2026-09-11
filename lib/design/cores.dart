import 'package:flutter/material.dart';

/// Paleta "Warm Scrapbook Social". Os valores vêm do `tailwind.config` das telas do Stitch
/// (`docs/design/stitch/*/code.html`), que é o que está desenhado; o DESIGN.md diverge no
/// primário (`#D85A38` na prosa) e perde. Esse terracota claro sobrevive só na marca.
@immutable
class Cores extends ThemeExtension<Cores> {
  const Cores({
    required this.primaria,
    required this.primariaContainer,
    required this.sobrePrimaria,
    required this.primariaFixa,
    required this.primariaFixaEscura,
    required this.sobrePrimariaFixa,
    required this.sobrePrimariaFixaVariante,
    required this.secundaria,
    required this.secundariaContainer,
    required this.secundariaFixa,
    required this.sobreSecundariaFixa,
    required this.terciaria,
    required this.terciariaFixa,
    required this.terciariaFixaEscura,
    required this.superficie,
    required this.superficieBaixa,
    required this.superficieContainer,
    required this.superficieAlta,
    required this.superficieMaisAlta,
    required this.superficieMaisBaixa,
    required this.sobreSuperficie,
    required this.sobreSuperficieVariante,
    required this.contorno,
    required this.contornoVariante,
    required this.erro,
    required this.erroContainer,
    required this.sobreErroContainer,
    required this.superficieInversa,
    required this.sobreSuperficieInversa,
  });

  final Color primaria;
  final Color primariaContainer;
  final Color sobrePrimaria;
  final Color primariaFixa;
  final Color primariaFixaEscura;
  final Color sobrePrimariaFixa;
  final Color sobrePrimariaFixaVariante;
  final Color secundaria;
  final Color secundariaContainer;
  final Color secundariaFixa;
  final Color sobreSecundariaFixa;
  final Color terciaria;
  final Color terciariaFixa;
  final Color terciariaFixaEscura;
  final Color superficie;
  final Color superficieBaixa;
  final Color superficieContainer;
  final Color superficieAlta;
  final Color superficieMaisAlta;
  final Color superficieMaisBaixa;
  final Color sobreSuperficie;
  final Color sobreSuperficieVariante;
  final Color contorno;
  final Color contornoVariante;
  final Color erro;
  final Color erroContainer;
  final Color sobreErroContainer;
  final Color superficieInversa;
  final Color sobreSuperficieInversa;

  static const claras = Cores(
    primaria: Color(0xFFA53616),
    primariaContainer: Color(0xFFC64D2C),
    sobrePrimaria: Color(0xFFFFFFFF),
    primariaFixa: Color(0xFFFFDBD1),
    primariaFixaEscura: Color(0xFFFFB5A1),
    sobrePrimariaFixa: Color(0xFF3C0800),
    sobrePrimariaFixaVariante: Color(0xFF872002),
    secundaria: Color(0xFF845400),
    secundariaContainer: Color(0xFFFFB142),
    secundariaFixa: Color(0xFFFFDDB6),
    sobreSecundariaFixa: Color(0xFF2A1800),
    terciaria: Color(0xFF48624E),
    terciariaFixa: Color(0xFFCDEAD0),
    terciariaFixaEscura: Color(0xFFB1CEB5),
    superficie: Color(0xFFFDF9F2),
    superficieBaixa: Color(0xFFF7F3EC),
    superficieContainer: Color(0xFFF1EDE6),
    superficieAlta: Color(0xFFEBE8E1),
    superficieMaisAlta: Color(0xFFE6E2DB),
    superficieMaisBaixa: Color(0xFFFFFFFF),
    sobreSuperficie: Color(0xFF1C1C18),
    sobreSuperficieVariante: Color(0xFF58423C),
    contorno: Color(0xFF8C716A),
    contornoVariante: Color(0xFFDFC0B8),
    erro: Color(0xFFBA1A1A),
    erroContainer: Color(0xFFFFDAD6),
    sobreErroContainer: Color(0xFF93000A),
    superficieInversa: Color(0xFF31302C),
    sobreSuperficieInversa: Color(0xFFF4F0E9),
  );

  static Cores de(BuildContext context) =>
      Theme.of(context).extension<Cores>()!;

  // Um tema só por enquanto: quando o escuro chegar, copyWith e lerp ganham campo a campo.
  @override
  Cores copyWith() => this;

  @override
  Cores lerp(Cores? other, double t) => t < 0.5 ? this : (other ?? this);
}
