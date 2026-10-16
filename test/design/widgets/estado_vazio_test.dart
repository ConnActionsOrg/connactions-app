import 'package:connactions_app/design/widgets/estado_vazio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../apoio/montar.dart';

void main() {
  testWidgets('mostra ícone, título, texto e a ação', (tester) async {
    await tester.pumpWidget(
      montar(
        EstadoVazio(
          icone: Symbols.local_cafe,
          titulo: 'Nenhuma turma por aqui ainda',
          texto:
              'Quando você entrar numa turma, a atividade da vez aparece aqui.',
          acao: FilledButton(
            onPressed: () {},
            child: const Text('Criar turma'),
          ),
        ),
      ),
    );

    expect(find.byIcon(Symbols.local_cafe), findsOneWidget);
    expect(find.text('Nenhuma turma por aqui ainda'), findsOneWidget);
    expect(
      find.text(
        'Quando você entrar numa turma, a atividade da vez aparece aqui.',
      ),
      findsOneWidget,
    );
    expect(find.text('Criar turma'), findsOneWidget);
  });

  testWidgets('sem texto, só o ícone, o título e a ação', (tester) async {
    await tester.pumpWidget(
      montar(
        EstadoVazio(
          icone: Symbols.group_add,
          titulo: 'Você ainda não tem amigos no app',
          acao: FilledButton(
            onPressed: () {},
            child: const Text('Conectar amigo'),
          ),
        ),
      ),
    );

    // o título e o rótulo do botão, e nenhum texto vazio no lugar da frase
    expect(find.byType(Text), findsNWidgets(2));
    expect(find.text('Você ainda não tem amigos no app'), findsOneWidget);
    expect(find.text('Conectar amigo'), findsOneWidget);
  });
}
