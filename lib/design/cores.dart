import 'package:flutter/material.dart';

/// Identidade aprovada: tinta ameixa, superfícies claras e acentos pastel.
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

  static const coral = Color(0xFFF3A0A8);
  static const damasco = Color(0xFFF6BB92);
  static const menta = Color(0xFFA8D6B5);
  static const ceu = Color(0xFF9BCDE4);
  static const pervinca = Color(0xFFAFB6E9);
  static const lilas = Color(0xFFCBB0E3);

  static const claras = Cores(
    primaria: Color(0xFF301539),
    primariaContainer: Color(0xFF50305E),
    sobrePrimaria: Color(0xFFFFFFFF),
    primariaFixa: Color(0xFFD7C1FF),
    primariaFixaEscura: Color(0xFFCBB0E3),
    sobrePrimariaFixa: Color(0xFF301539),
    sobrePrimariaFixaVariante: Color(0xFF50305E),
    secundaria: Color(0xFF69501B),
    secundariaContainer: Color(0xFFF1DC87),
    secundariaFixa: Color(0xFFF9E69F),
    sobreSecundariaFixa: Color(0xFF301539),
    terciaria: Color(0xFF325B42),
    terciariaFixa: Color(0xFFC0E4CB),
    terciariaFixaEscura: Color(0xFFA8D6B5),
    superficie: Color(0xFFFFFFFF),
    superficieBaixa: Color(0xFFFAF8FC),
    superficieContainer: Color(0xFFF3EDF8),
    superficieAlta: Color(0xFFEEE5DD),
    superficieMaisAlta: Color(0xFFE8DEEF),
    superficieMaisBaixa: Color(0xFFFFFFFF),
    sobreSuperficie: Color(0xFF301539),
    sobreSuperficieVariante: Color(0xFF75647D),
    contorno: Color(0xFF99869F),
    contornoVariante: Color(0xFFE9E1EF),
    erro: Color(0xFFA42E49),
    erroContainer: Color(0xFFFFE8EC),
    sobreErroContainer: Color(0xFF702032),
    superficieInversa: Color(0xFF301539),
    sobreSuperficieInversa: Color(0xFFFFFFFF),
  );

  static Cores de(BuildContext context) =>
      Theme.of(context).extension<Cores>()!;

  // Um tema só por enquanto: quando o escuro chegar, copyWith e lerp ganham campo a campo.
  @override
  Cores copyWith() => this;

  @override
  Cores lerp(Cores? other, double t) => t < 0.5 ? this : (other ?? this);
}
