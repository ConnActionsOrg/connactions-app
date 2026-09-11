import 'package:flutter/material.dart';

import 'cores.dart';
import 'medidas.dart';
import 'tipografia.dart';

/// Monta o ThemeData a partir dos tokens. Botão, campo, cartão, switch e aviso ganham o visual
/// aqui, para nenhuma tela ter de repetir estilo.
ThemeData temaClaro() {
  const cores = Cores.claras;
  final tipografia = Tipografia.padrao(cores);

  final esquema = ColorScheme(
    brightness: Brightness.light,
    primary: cores.primaria,
    onPrimary: cores.sobrePrimaria,
    primaryContainer: cores.primariaContainer,
    onPrimaryContainer: const Color(0xFFFFFBFF),
    secondary: cores.secundaria,
    onSecondary: Colors.white,
    secondaryContainer: cores.secundariaContainer,
    onSecondaryContainer: const Color(0xFF6F4600),
    tertiary: cores.terciaria,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFF607B65),
    onTertiaryContainer: const Color(0xFFF6FFF4),
    error: cores.erro,
    onError: Colors.white,
    errorContainer: cores.erroContainer,
    onErrorContainer: cores.sobreErroContainer,
    surface: cores.superficie,
    onSurface: cores.sobreSuperficie,
    surfaceContainerLowest: cores.superficieMaisBaixa,
    surfaceContainerLow: cores.superficieBaixa,
    surfaceContainer: cores.superficieContainer,
    surfaceContainerHigh: cores.superficieAlta,
    surfaceContainerHighest: cores.superficieMaisAlta,
    onSurfaceVariant: cores.sobreSuperficieVariante,
    outline: cores.contorno,
    outlineVariant: cores.contornoVariante,
    inverseSurface: cores.superficieInversa,
    onInverseSurface: cores.sobreSuperficieInversa,
    inversePrimary: cores.primariaFixaEscura,
    surfaceTint: Colors.transparent,
  );

  OutlineInputBorder borda(Color cor, double largura) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Raios.padrao),
    borderSide: largura == 0
        ? BorderSide.none
        : BorderSide(color: cor, width: largura),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: cores.superficie,
    fontFamily: Tipografia.familiaTexto,
    textTheme: TextTheme(
      displaySmall: tipografia.displayGrande,
      headlineLarge: tipografia.tituloGrande,
      headlineMedium: tipografia.tituloMedio,
      headlineSmall: tipografia.tituloPequeno,
      titleMedium: tipografia.rotuloTitulo,
      bodyLarge: tipografia.corpoGrande,
      bodyMedium: tipografia.corpoMedio,
      bodySmall: tipografia.corpoPequeno,
      labelLarge: tipografia.etiquetaGrande,
      labelMedium: tipografia.etiquetaMedia,
      labelSmall: tipografia.etiquetaPequena,
    ),
    extensions: [cores, tipografia],
    appBarTheme: AppBarTheme(
      backgroundColor: cores.superficie,
      foregroundColor: cores.sobreSuperficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cores.primaria,
        foregroundColor: cores.sobrePrimaria,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: Espacos.lg),
        shape: const StadiumBorder(),
        textStyle: tipografia.etiquetaGrande,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: cores.superficieContainer,
        foregroundColor: cores.sobreSuperficie,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: Espacos.lg),
        side: BorderSide(color: cores.contornoVariante, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: tipografia.etiquetaGrande,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cores.primaria,
        textStyle: tipografia.etiquetaGrande,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cores.superficieContainer,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Espacos.md,
        vertical: 14,
      ),
      border: borda(cores.superficieContainer, 0),
      enabledBorder: borda(cores.superficieContainer, 0),
      focusedBorder: borda(cores.primaria, 1.5),
      hintStyle: tipografia.corpoMedio.copyWith(
        color: cores.sobreSuperficieVariante,
      ),
    ),
    cardTheme: CardThemeData(
      color: cores.superficieBaixa,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raios.medio),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? cores.sobrePrimaria
            : cores.contorno,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? cores.primaria
            : cores.superficieMaisAlta,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cores.superficieInversa,
      contentTextStyle: tipografia.corpoMedio.copyWith(
        color: cores.sobreSuperficieInversa,
      ),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: cores.primaria),
    dividerColor: cores.contornoVariante,
  );
}
