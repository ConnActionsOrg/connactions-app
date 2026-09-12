import 'package:connactions_app/app/autenticador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/app_de_teste.dart';
import '../apoio/autenticador_falso.dart';

void main() {
  testWidgets('deslogado cai na entrada', (tester) async {
    await tester.pumpWidget(appDeTeste(autenticador: AutenticadorFalso()));
    await tester.pumpAndSettle();
    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  testWidgets('entrar com Google leva ao feed vazio', (tester) async {
    final autenticador = AutenticadorFalso();
    await tester.pumpWidget(appDeTeste(autenticador: autenticador));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();

    expect(autenticador.chamadas, ['entrar']);
    expect(find.text('Nenhuma turma por aqui ainda'), findsOneWidget);
  });

  testWidgets('falha no login vira aviso e a tela fica', (tester) async {
    final autenticador = AutenticadorFalso()
      ..falhaAoEntrar = const ErroDeLogin('Sem rede agora.');
    await tester.pumpWidget(appDeTeste(autenticador: autenticador));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();

    expect(find.text('Sem rede agora.'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);

    // o SnackBar arma um Timer de 4s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('login cancelado não mostra aviso', (tester) async {
    final autenticador = AutenticadorFalso()
      ..falhaAoEntrar = const ErroDeLogin('Login cancelado.', cancelado: true);
    await tester.pumpWidget(appDeTeste(autenticador: autenticador));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();

    expect(find.text('Login cancelado.'), findsNothing);
    expect(autenticador.chamadas, ['entrar']);
  });

  testWidgets('logado navega pelas quatro abas', (tester) async {
    await tester.pumpWidget(appDeTeste());
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma turma por aqui ainda'), findsOneWidget);

    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
    expect(find.text('O diário começa vazio'), findsOneWidget);

    await tester.tap(find.text('Comunidade'));
    await tester.pumpAndSettle();
    expect(find.text('A comunidade ainda está quieta'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    // o botão de sair vive no fim do ListView da tela e fica abaixo da dobra no viewport de teste
    await tester.scrollUntilVisible(
      find.text('Sair da conta'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta'), findsOneWidget);
  });

  testWidgets('sair volta para a entrada', (tester) async {
    final autenticador = AutenticadorFalso(conta: contaDeTeste);
    await tester.pumpWidget(appDeTeste(autenticador: autenticador));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    // o botão de sair vive no fim do ListView da tela e fica abaixo da dobra no viewport de teste
    await tester.scrollUntilVisible(
      find.text('Sair da conta'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(autenticador.chamadas, ['sair']);
    expect(find.text('Entrar com Google'), findsOneWidget);
  });
}
