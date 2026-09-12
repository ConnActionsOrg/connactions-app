import 'package:connactions_app/api/erro_da_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/autenticador_falso.dart';
import '../../apoio/fake_api.dart';

Future<void> abrirPerfil(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra nome, handle, bio e código vindos da API', (
    tester,
  ) async {
    await abrirPerfil(
      tester,
      FakeApi(
        eu: euDeTeste(
          nome: 'Marina Duarte',
          handle: 'marina.d',
          bio: 'Colecionando risadas ✨',
        ),
      ),
    );

    expect(find.text('Marina Duarte'), findsOneWidget);
    expect(find.text('@marina.d'), findsOneWidget);
    expect(find.text('Colecionando risadas ✨'), findsOneWidget);
    expect(find.text('ABCDEFGH'), findsOneWidget);
    expect(
      find.text('MD'),
      findsOneWidget,
      reason: 'sem foto, o avatar mostra as iniciais',
    );
  });

  testWidgets('sem bio, o cartão da bio não aparece', (tester) async {
    await abrirPerfil(tester, FakeApi(eu: euDeTeste(bio: '')));
    expect(find.text('Marina Duarte'), findsOneWidget);
    expect(find.textContaining('Colecionando'), findsNothing);
  });

  testWidgets('o interruptor de visibilidade grava na API', (tester) async {
    final api = FakeApi(eu: euDeTeste(atividadesVisiveis: true));
    await abrirPerfil(tester, api);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(
      find.text('Amigos conectados veem o que você concluiu.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'atualizarVisibilidade:false');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Só você vê o que concluiu.'), findsOneWidget);
  });

  testWidgets('se a API recusa a troca, o interruptor volta e avisa', (
    tester,
  ) async {
    final api = FakeApi(
      eu: euDeTeste(atividadesVisiveis: true),
      falhaAoAtualizar: const ErroDeRede('caiu'),
    );
    await abrirPerfil(tester, api);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('Não consegui salvar. Tente de novo.'), findsOneWidget);

    // o SnackBar arma um Timer de 4s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('falha ao carregar mostra o erro, e tentar de novo recarrega', (
    tester,
  ) async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoObter: const ErroDeRede('caiu'),
    );
    await abrirPerfil(tester, api);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );

    api.falhaAoObter = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Marina Duarte'), findsOneWidget);
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrirPerfil(tester, FakeApi(eu: euDeTeste()));
    final scaffold = find.byType(Scaffold).last;
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });

  testWidgets('com falha ao carregar, ainda dá para sair', (tester) async {
    final autenticador = AutenticadorFalso(conta: contaDeTeste);
    await tester.pumpWidget(
      appDeTeste(
        autenticador: autenticador,
        api: FakeApi(eu: euDeTeste(), falhaAoObter: const ErroDeRede('caiu')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar de novo'), findsOneWidget);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(autenticador.chamadas, ['sair']);
    expect(find.text('Entrar com Google'), findsOneWidget);
  });
}
