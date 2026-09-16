import 'package:connactions_app/features/turmas/folha_de_turmas.dart';
import 'package:connactions_app/features/turmas/seletor_de_turma.dart';
import 'package:connactions_app/features/turmas/tela_da_turma.dart';
import 'package:connactions_app/features/turmas/tela_de_entrar_na_turma.dart';
import 'package:connactions_app/features/turmas/tela_de_nova_turma.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/preferencias_em_memoria.dart';

FakeApi duasTurmas() => FakeApi(
  eu: euDeTeste(),
  turmas: [
    turmaDeTeste(id: 'turma-1'),
    turmaDeTeste(id: 'turma-2', nome: 'Cozinha & Prosa', emoji: '☕'),
  ],
);

Future<void> abrirFolha(
  WidgetTester tester, {
  FakeApi? api,
  PreferenciasEmMemoria? preferencias,
}) async {
  await tester.pumpWidget(
    appDeTeste(api: api ?? duasTurmas(), preferencias: preferencias),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SeletorDeTurma));
  await tester.pumpAndSettle();
  expect(find.text('Suas turmas'), findsOneWidget);
}

Finder cartao(String nome) => find.widgetWithText(CartaoDeTurma, nome);

void main() {
  testWidgets('lista as turmas e marca a ativa', (tester) async {
    await abrirFolha(tester);

    expect(find.text('Toque para trocar a turma ativa'), findsOneWidget);
    expect(find.byType(CartaoDeTurma), findsNWidgets(2));
    expect(find.text('Ativa'), findsOneWidget);
    expect(
      find.descendant(
        of: cartao('Turma do Domingo'),
        matching: find.text('Ativa'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cartao('Cozinha & Prosa'),
        matching: find.text('Ativa'),
      ),
      findsNothing,
    );
  });

  testWidgets('tocar em outra turma troca a ativa, persiste e fecha a folha', (
    tester,
  ) async {
    final prefs = PreferenciasEmMemoria();
    await abrirFolha(tester, preferencias: prefs);

    await tester.tap(cartao('Cozinha & Prosa'));
    await tester.pumpAndSettle();

    expect(find.text('Suas turmas'), findsNothing);
    expect(prefs.valores['turma_ativa_id'], 'turma-2');
    expect(
      find.descendant(
        of: find.byType(SeletorDeTurma),
        matching: find.text('Cozinha & Prosa'),
      ),
      findsOneWidget,
    );

    // o Diário acompanha a mesma turma ativa
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('☕ Cozinha & Prosa vão aparecer aqui'),
      findsOneWidget,
    );
  });

  testWidgets('tocar na turma já ativa só fecha a folha', (tester) async {
    final prefs = PreferenciasEmMemoria();
    await abrirFolha(tester, preferencias: prefs);

    await tester.tap(cartao('Turma do Domingo'));
    await tester.pumpAndSettle();

    expect(find.text('Suas turmas'), findsNothing);
    expect(prefs.valores.containsKey('turma_ativa_id'), isFalse);
  });

  testWidgets('"Ver turma" abre a tela da turma', (tester) async {
    await abrirFolha(tester);

    await tester.tap(
      find.descendant(
        of: cartao('Cozinha & Prosa'),
        matching: find.byTooltip('Ver turma'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TelaDaTurma), findsOneWidget);
    expect(find.text('☕ Cozinha & Prosa'), findsOneWidget);
  });

  testWidgets('"Criar nova turma" abre a tela de criar', (tester) async {
    await abrirFolha(tester);
    await tester.tap(find.text('Criar nova turma'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDeNovaTurma), findsOneWidget);
    expect(find.text('Suas turmas'), findsNothing);
  });

  testWidgets('"Entrar com código de convite" abre a tela de entrar', (
    tester,
  ) async {
    await abrirFolha(tester);
    await tester.tap(find.text('Entrar com código de convite'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDeEntrarNaTurma), findsOneWidget);
  });

  testWidgets('a pílula tem nome acessível', (tester) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(appDeTeste(api: duasTurmas()));
    await tester.pumpAndSettle();

    // O Semantics da pílula funde o rótulo próprio com o texto dos descendentes (nome, "N membros
    // · vez de X"): casar por RegExp âncorado no início, como a própria documentação recomenda
    // quando o framework combina rótulos.
    expect(find.bySemanticsLabel(RegExp('^Trocar de turma')), findsOneWidget);
    // dispose síncrono na última linha: addTearDown dispararia depois da verificação de fim
    semantica.dispose();
  });
}
