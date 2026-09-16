import 'dart:io';

import 'package:connactions_app/design/cores.dart';
import 'package:connactions_app/design/tema.dart';
import 'package:connactions_app/design/tipografia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Constantes congeladas de propósito: se alguém mexer no token, este teste precisa cair.
  const superficie = Color(0xFFFDF9F2);
  const primaria = Color(0xFFA53616);

  test('o tema carrega as cores do Stitch', () {
    final tema = temaClaro();
    expect(tema.scaffoldBackgroundColor, superficie);
    expect(tema.colorScheme.primary, primaria);
    expect(tema.extension<Cores>()!.superficieBaixa, const Color(0xFFF7F3EC));
    expect(
      tema.extension<Cores>()!.sobreSuperficieVariante,
      const Color(0xFF58423C),
    );
  });

  test(
    'títulos em Epilogue e texto em Plus Jakarta Sans, na escala do Stitch',
    () {
      final tema = temaClaro();
      final tipografia = tema.extension<Tipografia>()!;
      expect(tema.textTheme.headlineMedium!.fontFamily, 'Epilogue');
      expect(tema.textTheme.headlineMedium!.fontSize, 22);
      expect(tema.textTheme.headlineMedium!.height, closeTo(30 / 22, 0.001));
      expect(tema.textTheme.bodyMedium!.fontFamily, 'PlusJakartaSans');
      expect(tema.textTheme.bodyMedium!.fontSize, 14);
      expect(tipografia.etiquetaPequena.fontWeight, FontWeight.w700);
      expect(tipografia.tituloGrande.letterSpacing, closeTo(-0.52, 0.001));
    },
  );

  test('botão primário é pílula terracota de 52px', () {
    final estilo = temaClaro().filledButtonTheme.style!;
    expect(estilo.backgroundColor!.resolve({}), primaria);
    expect(estilo.minimumSize!.resolve({})!.height, 52);
    expect(estilo.shape!.resolve({}), isA<StadiumBorder>());
  });

  test('folha e diálogo saem do tema', () {
    final tema = temaClaro();
    final folha = tema.bottomSheetTheme;
    expect(folha.backgroundColor, superficie);
    expect(folha.showDragHandle, isTrue);
    final forma = folha.shape! as RoundedRectangleBorder;
    expect(
      (forma.borderRadius as BorderRadius).topLeft,
      const Radius.circular(32),
    );
    expect(tema.dialogTheme.backgroundColor, const Color(0xFFF7F3EC));
    expect(tema.dialogTheme.titleTextStyle!.fontFamily, 'Epilogue');
  });

  test('as fontes estão empacotadas', () {
    for (final arquivo in [
      'Epilogue-SemiBold',
      'Epilogue-Bold',
      'PlusJakartaSans-Regular',
      'PlusJakartaSans-SemiBold',
      'PlusJakartaSans-Bold',
    ]) {
      expect(
        File('assets/fontes/$arquivo.ttf').existsSync(),
        isTrue,
        reason: '$arquivo.ttf faltando: rode tool/baixar_fontes.ps1',
      );
    }
  });
}
