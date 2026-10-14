import 'package:connactions_app/api/modelos/capa_do_diario.dart';
import 'package:connactions_app/design/cores.dart';
import 'package:connactions_app/features/diario/paleta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// WCAG 2.1: razão de contraste entre as luminâncias relativas.
double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  const cores = Cores.claras;

  test(
    'cada paleta pinta a capa com fundo próprio, sem repetir o de outra',
    () {
      final fundos = {
        for (final p in PaletaDoDiario.values) p: coresDaPaleta(p, cores).capa,
      };
      expect(fundos[PaletaDoDiario.terracota], cores.primaria);
      expect(fundos[PaletaDoDiario.ambar], cores.secundariaContainer);
      expect(fundos[PaletaDoDiario.salvia], cores.terciaria);
      expect(fundos[PaletaDoDiario.areia], cores.superficieAlta);
      expect(fundos.values.toSet(), hasLength(PaletaDoDiario.values.length));
    },
  );

  test('só a Areia tem contorno na capa', () {
    for (final p in PaletaDoDiario.values) {
      final borda = coresDaPaleta(p, cores).bordaDaCapa;
      expect(borda == null, p != PaletaDoDiario.areia, reason: p.name);
    }
  });

  test('o texto da capa e o do chip marcado passam de 4,5:1 (AA) em todas', () {
    for (final p in PaletaDoDiario.values) {
      final c = coresDaPaleta(p, cores);
      expect(
        _contraste(c.textoDaCapa, c.capa),
        greaterThan(4.5),
        reason: 'texto da capa, ${p.name}',
      );
      expect(
        _contraste(c.chipTexto, c.chipFundo),
        greaterThan(4.5),
        reason: 'chip marcado, ${p.name}',
      );
    }
  });
}
