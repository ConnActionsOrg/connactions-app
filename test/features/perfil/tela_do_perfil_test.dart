import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/turma.dart';
import 'package:connactions_app/features/perfil/cartao_de_atividade_feita.dart';
import 'package:connactions_app/features/perfil/codigo_de_amigo.dart';
import 'package:connactions_app/features/perfil/fileira_de_amigos.dart';
import 'package:connactions_app/features/perfil/linha_de_contadores.dart';
import 'package:connactions_app/features/perfil/tela_da_pessoa.dart';
import 'package:connactions_app/features/perfil/tela_de_amigos.dart';
import 'package:connactions_app/features/perfil/tela_de_conectar_amigo.dart';
import 'package:connactions_app/features/perfil/tela_do_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/autenticador_falso.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/notificador_falso.dart';

final eu = pessoaDoEu(euDeTeste());

/// A Bia e o Caio são contas da API; as minhas atividades feitas são [minhas].
FakeApi apiDoPerfil({
  List<(String, String)> conexoes = const [],
  List<Feita> minhas = const [],
  List<Turma> turmas = const [],
}) => FakeApi(
  eu: euDeTeste(bio: 'Colecionando risadas ✨'),
  turmas: turmas,
  usuarios: [
    usuarioDeTeste(),
    usuarioDeTeste(
      id: 'pessoa-caio',
      handle: 'caio',
      nome: 'Caio Lima',
      codigoDeAmigo: 'CKXZ2345',
    ),
  ],
  conexoes: conexoes,
  feitasPor: {eu.id: minhas},
);

Future<void> abrirPerfil(
  WidgetTester tester,
  FakeApi api, {
  CompartilhadorFalso? compartilhador,
}) async {
  await tester.pumpWidget(appDeTeste(api: api, compartilhador: compartilhador));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
}

/// A lista vertical do Perfil: a fileira de amigos também é um Scrollable, e vem depois dela.
Finder listaDoPerfil() => find
    .descendant(
      of: find.byType(TelaDoPerfil),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(alvo, 200, scrollable: listaDoPerfil());
  await tester.pumpAndSettle();
}

/// Alta o bastante para a identidade e os amigos caberem na tela de uma vez: na de 800×600 a
/// fileira fica abaixo da dobra, e o `find` ignora o que está fora da área visível.
void telaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

int leituras(FakeApi api, String chamada) =>
    api.chamadas.where((c) => c == chamada).length;

/// O SnackBar arma um Timer de 4 s; deixá-lo pendente reprova o teste no teardown.
Future<void> esperarOAvisoSair(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

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
    expect(
      find.text('MD'),
      findsOneWidget,
      reason: 'sem foto, o avatar mostra as iniciais',
    );
    // o código mora no cartão "Chamar mais amigos?", perto do fim
    await rolarAte(tester, find.text('ABCDEFGH'));
    expect(find.text('ABCDEFGH'), findsOneWidget);
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

    expect(api.chamadas.last, 'atualizarEu:{"atividades_visiveis":false}');
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
    final scaffold = find.descendant(
      of: find.byType(TelaDoPerfil),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });

  testWidgets('o cartão de identidade tem o botão de editar', (tester) async {
    await abrirPerfil(tester, FakeApi(eu: euDeTeste()));
    expect(find.text('Editar perfil'), findsOneWidget);
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

  testWidgets('carregando mostra o indicador e ainda dá para sair', (
    tester,
  ) async {
    final autenticador = AutenticadorFalso(conta: contaDeTeste);
    final api = FakeApi(eu: euDeTeste())..segurarObterEu = Completer<void>();
    await tester.pumpWidget(appDeTeste(autenticador: autenticador, api: api));
    // sem pumpAndSettle: o obterEu está preso no Completer, e o indicador tem animação
    // infinita — os dois pendurariam pumpAndSettle indefinidamente.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);

    await tester.tap(find.text('Sair da conta'));
    await tester.pump();
    api.segurarObterEu!.complete();
    await tester.pumpAndSettle();

    expect(autenticador.chamadas, ['sair']);
    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  testWidgets('"Sair da conta" tira o aparelho da API e do Firebase', (
    tester,
  ) async {
    final autenticador = AutenticadorFalso(conta: contaDeTeste);
    final api = FakeApi(eu: euDeTeste());
    final notificador = NotificadorFalso();
    await tester.pumpWidget(
      appDeTeste(
        autenticador: autenticador,
        api: api,
        notificador: notificador,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    // o botão vive no fim do ListView, abaixo da dobra no viewport de teste
    await rolarAte(tester, find.text('Sair da conta'));

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('removerDispositivo:token-fcm-1'));
    expect(notificador.chamadas, contains('apagarToken'));
    expect(autenticador.chamadas, ['sair']);
    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  testWidgets('os contadores ficam entre a bio e o "Editar perfil"', (
    tester,
  ) async {
    await abrirPerfil(
      tester,
      apiDoPerfil(
        turmas: [
          turmaDeTeste(),
          turmaDeTeste(id: 'turma-2'),
        ],
        minhas: [
          feitaDeTeste(id: 'f1'),
          feitaDeTeste(id: 'f2'),
          feitaDeTeste(id: 'f3'),
        ],
        conexoes: [(eu.id, 'pessoa-bia')],
      ),
    );

    final linha = find.byType(LinhaDeContadores);
    for (final texto in ['2', 'Turmas', '3', 'Atividades', '1', 'Conexão']) {
      expect(
        find.descendant(of: linha, matching: find.text(texto)),
        findsOneWidget,
        reason: texto,
      );
    }
    final bio = tester.getTopLeft(find.text('Colecionando risadas ✨')).dy;
    final contadores = tester.getTopLeft(linha).dy;
    final editar = tester.getTopLeft(find.text('Editar perfil')).dy;
    expect(bio, lessThan(contadores));
    expect(contadores, lessThan(editar));
  });

  testWidgets(
    'os contadores mostram "–" enquanto carregam, e com erro a linha some e o resto segue',
    (tester) async {
      telaAlta(tester);
      final api = apiDoPerfil()
        ..segurarObterPerfil = Completer<void>()
        ..falhaAoObterPerfil = const ErroDeRede('caiu');
      await tester.pumpWidget(appDeTeste(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfil'));
      await tester.pump();
      await tester.pump();

      expect(find.text('–'), findsNWidgets(3));

      api.segurarObterPerfil!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(LinhaDeContadores), findsNothing);
      expect(find.text('Marina Duarte'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.byType(FileiraDeAmigos), findsOneWidget);
    },
  );

  testWidgets(
    'a fileira tem o "Conectar amigo" primeiro e os amigos, e o "Ver todos (N)" abre a lista',
    (tester) async {
      telaAlta(tester);
      await abrirPerfil(
        tester,
        apiDoPerfil(conexoes: [(eu.id, 'pessoa-bia'), (eu.id, 'pessoa-caio')]),
      );

      expect(find.text('Amigos'), findsOneWidget);
      final conectar = tester.getTopLeft(find.text('Conectar amigo')).dx;
      expect(conectar, lessThan(tester.getTopLeft(find.text('Bia')).dx));
      expect(
        tester.getTopLeft(find.text('Bia')).dx,
        lessThan(tester.getTopLeft(find.text('Caio')).dx),
      );

      await tester.tap(find.text('Ver todos (2)'));
      await tester.pumpAndSettle();
      expect(find.byType(TelaDeAmigos), findsOneWidget);
    },
  );

  testWidgets(
    'sem amigos, a fileira só com o "Conectar amigo" e sem o "Ver todos"',
    (tester) async {
      telaAlta(tester);
      await abrirPerfil(tester, apiDoPerfil());

      expect(find.text('Conectar amigo'), findsOneWidget);
      expect(find.textContaining('Ver todos'), findsNothing);
    },
  );

  testWidgets(
    'o "Conectar amigo" abre a tela de conectar, e um amigo abre o perfil dele',
    (tester) async {
      telaAlta(tester);
      await abrirPerfil(tester, apiDoPerfil(conexoes: [(eu.id, 'pessoa-bia')]));

      await tester.tap(find.text('Conectar amigo'));
      await tester.pumpAndSettle();
      expect(find.byType(TelaDeConectarAmigo), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bia'));
      await tester.pumpAndSettle();
      expect(find.byType(TelaDaPessoa), findsOneWidget);
      expect(find.text('Bia Souza'), findsOneWidget);
    },
  );

  testWidgets('as minhas atividades concluídas, e o vazio delas', (
    tester,
  ) async {
    await abrirPerfil(
      tester,
      apiDoPerfil(
        minhas: [feitaDeTeste(id: 'f1', titulo: 'Piquenique')],
      ),
    );
    await rolarAte(tester, find.text('Piquenique'));
    expect(find.text('Minhas atividades concluídas'), findsOneWidget);
    expect(find.byType(CartaoDeAtividadeFeita), findsOneWidget);

    await abrirPerfil(tester, apiDoPerfil());
    await rolarAte(
      tester,
      find.text('Suas atividades encerradas aparecem aqui.'),
    );
    expect(find.byType(CartaoDeAtividadeFeita), findsNothing);
  });

  testWidgets(
    'o cartão "Chamar mais amigos?" compartilha a mensagem com o meu código',
    (tester) async {
      final compartilhador = CompartilhadorFalso();
      await abrirPerfil(tester, apiDoPerfil(), compartilhador: compartilhador);

      await rolarAte(tester, find.text('Chamar mais amigos?'));
      expect(
        find.text('Compartilhe seu código para criar novas conexões.'),
        findsOneWidget,
      );
      expect(find.text('ABCDEFGH'), findsOneWidget);
      await rolarAte(tester, find.widgetWithText(FilledButton, 'Compartilhar'));
      await tester.tap(find.widgetWithText(FilledButton, 'Compartilhar'));
      await tester.pumpAndSettle();

      expect(compartilhador.textos, [textoDoCodigoDeAmigo('ABCDEFGH')]);
    },
  );

  testWidgets(
    'os amigos com erro não derrubam o resto, e o "Tentar de novo" os traz',
    (tester) async {
      telaAlta(tester);
      final api = apiDoPerfil(conexoes: [(eu.id, 'pessoa-bia')])
        ..falhaAoListarConexoes = const ErroDeRede('caiu');
      await abrirPerfil(tester, api);

      expect(find.text('Não consegui carregar seus amigos.'), findsOneWidget);
      expect(find.text('Conectar amigo'), findsOneWidget);
      expect(find.text('Marina Duarte'), findsOneWidget);
      expect(find.byType(LinhaDeContadores), findsOneWidget);

      api.falhaAoListarConexoes = null;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();

      expect(find.text('Não consegui carregar seus amigos.'), findsNothing);
      expect(find.text('Bia'), findsOneWidget);
    },
  );

  testWidgets('as atividades carregando ou com erro não derrubam o resto', (
    tester,
  ) async {
    telaAlta(tester);
    final api = apiDoPerfil(conexoes: [(eu.id, 'pessoa-bia')])
      ..segurarListarAtividadesFeitas = Completer<void>()
      ..falhaAoListarAtividadesFeitas = const ErroDeRede('caiu');
    await tester.pumpWidget(appDeTeste(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    // sem pumpAndSettle: a lista presa mostra um indicador que gira para sempre
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.text('Bia'), findsOneWidget);
    expect(find.byType(LinhaDeContadores), findsOneWidget);

    api.segurarListarAtividadesFeitas!.complete();
    await tester.pumpAndSettle();
    await rolarAte(tester, find.text('Minhas atividades concluídas'));

    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('Algo não deu certo'), findsNothing);
  });

  testWidgets(
    'puxar para atualizar relê os amigos, os contadores e as atividades, e não o perfil',
    (tester) async {
      // as atividades só são lidas quando a seção delas é montada, e na tela baixa ela fica longe
      telaAlta(tester);
      final api = apiDoPerfil(conexoes: [(eu.id, 'pessoa-bia')]);
      await abrirPerfil(tester, api);
      expect(leituras(api, 'listarAtividadesFeitas:${eu.id}:'), 1);
      // o Caio conectou do aparelho dele: sem realtime, só a próxima leitura o mostra
      api.conexoes.insert(0, ('pessoa-caio', eu.id));

      // o indicador só arma depois de um puxão de uns 17% da altura da lista
      await tester.fling(listaDoPerfil(), const Offset(0, 600), 1000);
      await tester.pumpAndSettle();

      expect(leituras(api, 'listarConexoes'), 2);
      expect(leituras(api, 'obterPerfil:${eu.id}'), 2);
      expect(leituras(api, 'listarAtividadesFeitas:${eu.id}:'), 2);
      expect(leituras(api, 'obterEu'), 1);
      expect(find.text('Caio'), findsOneWidget);
    },
  );

  testWidgets(
    'trocar de conta: o Perfil da conta nova não mostra nenhum amigo da anterior',
    (tester) async {
      // eu sou amiga do Caio; a Bia, da Dani. Com as minhas atividades, o "Sair da conta" fica
      // longe da fileira, e ela já saiu da árvore quando a conta sai.
      final api = FakeApi(
        eu: euDeTeste(),
        feitasPor: {
          eu.id: [for (var i = 1; i <= 4; i++) feitaDeTeste(id: 'f$i')],
        },
        usuarios: [
          usuarioDeTeste(),
          usuarioDeTeste(
            id: 'pessoa-caio',
            handle: 'caio',
            nome: 'Caio Lima',
            codigoDeAmigo: 'CKXZ2345',
          ),
          usuarioDeTeste(
            id: 'pessoa-dani',
            handle: 'dani',
            nome: 'Dani Rocha',
            codigoDeAmigo: 'DNRX2345',
          ),
        ],
        conexoes: [(eu.id, 'pessoa-caio'), ('pessoa-bia', 'pessoa-dani')],
      );
      final autenticador = AutenticadorFalso(conta: contaDeTeste);
      await tester.pumpWidget(appDeTeste(autenticador: autenticador, api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await rolarAte(tester, find.text('Caio'));
      expect(find.text('Caio'), findsOneWidget);

      await rolarAte(tester, find.text('Sair da conta'));
      // sem ninguém ouvindo, a lista fica parada com os amigos da conta que saiu
      expect(find.byType(FileiraDeAmigos, skipOffstage: false), findsNothing);
      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      api.entrarComo('pessoa-bia');
      final segurar = api.segurarListarConexoes = Completer<void>();
      await tester.tap(find.text('Entrar com Google'));
      await tester.pumpAndSettle();
      telaAlta(tester);
      await tester.tap(find.text('Perfil'));
      // sem pumpAndSettle: com a lista da conta nova presa, a fileira mostra o indicador
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text('Bia Souza'), findsOneWidget);
      expect(find.text('Caio'), findsNothing);
      segurar.complete();
      await tester.pumpAndSettle();
      expect(find.text('Dani'), findsOneWidget);
      expect(find.text('Caio'), findsNothing);
    },
  );
}
