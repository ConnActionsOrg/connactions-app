import 'package:connactions_app/design/cores.dart';
import 'package:connactions_app/design/widgets/barra_de_abas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../apoio/montar.dart';

const abas = [
  AbaDaBarra(rotulo: 'Feed', icone: Symbols.local_cafe),
  AbaDaBarra(rotulo: 'Diário', icone: Symbols.auto_stories),
  AbaDaBarra(rotulo: 'Comunidade', icone: Symbols.groups_2),
  AbaDaBarra(rotulo: 'Perfil', icone: Symbols.person),
];

void main() {
  testWidgets('tocar numa aba avisa o índice dela', (tester) async {
    int? escolhido;
    await tester.pumpWidget(
      montar(
        Align(
          alignment: Alignment.bottomCenter,
          child: BarraDeAbas(
            abas: abas,
            indiceAtivo: 0,
            aoSelecionar: (i) => escolhido = i,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Perfil'));
    expect(escolhido, 3);
  });

  testWidgets('a aba ativa fica em terracota e as outras em cinza quente', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(
        Align(
          alignment: Alignment.bottomCenter,
          child: BarraDeAbas(abas: abas, indiceAtivo: 0, aoSelecionar: (_) {}),
        ),
      ),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Symbols.local_cafe)).color,
      Cores.claras.primaria,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Symbols.person)).color,
      Cores.claras.sobreSuperficieVariante,
    );
  });
}
