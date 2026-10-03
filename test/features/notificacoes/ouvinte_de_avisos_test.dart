import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:connactions_app/features/perfil/tela_do_perfil.dart';
import 'package:connactions_app/features/turmas/seletor_de_turma.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/autenticador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/notificador_falso.dart';
import '../../apoio/preferencias_em_memoria.dart';

/// Como a API manda: os dados com o tipo e a turma, e a notificação com título e corpo.
RemoteMessage mensagem({
  String? turmaId,
  String tipo = 'sua_vez',
  String titulo = 'É a sua vez de propor!',
  String corpo = '☕ Cozinha & Prosa: Bia encerrou a rodada 1.',
}) => RemoteMessage(
  data: {'tipo': tipo, 'turma_id': ?turmaId},
  notification: RemoteNotification(title: titulo, body: corpo),
);

FakeApi apiComDuasTurmas() => FakeApi(
  eu: euDeTeste(),
  turmas: [
    turmaDeTeste(id: 'turma-1'),
    turmaDeTeste(id: 'turma-2', nome: 'Cozinha & Prosa', emoji: '☕'),
  ],
);

Finder naPilula(String texto) => find.descendant(
  of: find.byType(SeletorDeTurma),
  matching: find.text(texto),
);

int leiturasDeTurmas(FakeApi api) =>
    api.chamadas.where((c) => c == 'listarTurmas').length;

int leiturasDaAberta(FakeApi api, String turmaId) =>
    api.chamadas.where((c) => c == 'obterAtividadeAberta:$turmaId').length;

int leiturasDoDiario(FakeApi api, String turmaId) =>
    api.chamadas.where((c) => c == 'listarDiario:$turmaId:').length;

Future<void> abrir(
  WidgetTester tester, {
  required FakeApi api,
  required NotificadorFalso notificador,
  PreferenciasEmMemoria? preferencias,
  AutenticadorFalso? autenticador,
}) async {
  await tester.pumpWidget(
    appDeTeste(
      api: api,
      notificador: notificador,
      preferencias: preferencias,
      autenticador: autenticador,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('o toque que abriu o app troca a turma ativa e termina no Feed', (
    tester,
  ) async {
    final notificador = NotificadorFalso()
      ..mensagemAoAbrir = mensagem(turmaId: 'turma-2');
    final preferencias = PreferenciasEmMemoria({'turma_ativa_id': 'turma-1'});

    await abrir(
      tester,
      api: apiComDuasTurmas(),
      notificador: notificador,
      preferencias: preferencias,
    );

    expect(find.byType(TelaDoFeed), findsOneWidget);
    expect(naPilula('Cozinha & Prosa'), findsOneWidget);
    expect(preferencias.valores['turma_ativa_id'], 'turma-2');
  });

  testWidgets('o toque a frio sem sessão termina na entrada, sem erro', (
    tester,
  ) async {
    final notificador = NotificadorFalso()
      ..mensagemAoAbrir = mensagem(turmaId: 'turma-2');

    await abrir(
      tester,
      api: apiComDuasTurmas(),
      notificador: notificador,
      autenticador: AutenticadorFalso(),
    );

    expect(notificador.chamadas, contains('tocadoAoAbrir'));
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'o toque com o app no fundo troca a turma, relê e volta ao Feed',
    (tester) async {
      final api = apiComDuasTurmas();
      final notificador = NotificadorFalso();
      final preferencias = PreferenciasEmMemoria({'turma_ativa_id': 'turma-1'});
      await abrir(
        tester,
        api: api,
        notificador: notificador,
        preferencias: preferencias,
      );
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(TelaDoPerfil), findsOneWidget);
      final turmasLidas = leiturasDeTurmas(api);

      notificador.tocar(mensagem(turmaId: 'turma-2'));
      await tester.pumpAndSettle();

      expect(find.byType(TelaDoFeed), findsOneWidget);
      expect(naPilula('Cozinha & Prosa'), findsOneWidget);
      expect(preferencias.valores['turma_ativa_id'], 'turma-2');
      expect(leiturasDeTurmas(api), turmasLidas + 1);
    },
  );

  testWidgets('com o app aberto, o aviso vai para a tela e a turma é relida', (
    tester,
  ) async {
    final api = apiComDuasTurmas();
    final notificador = NotificadorFalso();
    await abrir(
      tester,
      api: api,
      notificador: notificador,
      preferencias: PreferenciasEmMemoria({'turma_ativa_id': 'turma-1'}),
    );
    // o Diário visitado fica montado e pausado atrás do Feed: a releitura dele aparece ao voltar
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    final turmasLidas = leiturasDeTurmas(api);
    final abertasLidas = leiturasDaAberta(api, 'turma-1');
    final diariosLidos = leiturasDoDiario(api, 'turma-1');

    notificador.receber(
      mensagem(
        turmaId: 'turma-1',
        tipo: 'registro_novo',
        titulo: '🌿 Turma do Domingo',
        corpo: 'Bia postou um registro em Piquenique',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('🌿 Turma do Domingo\nBia postou um registro em Piquenique'),
      findsOneWidget,
    );
    expect(leiturasDeTurmas(api), turmasLidas + 1);
    expect(leiturasDaAberta(api, 'turma-1'), abertasLidas + 1);
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
    expect(leiturasDoDiario(api, 'turma-1'), diariosLidos + 1);

    // o SnackBar arma um Timer de 4 s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('o aviso de outra turma com o app aberto não troca a ativa', (
    tester,
  ) async {
    final api = apiComDuasTurmas();
    final notificador = NotificadorFalso();
    final preferencias = PreferenciasEmMemoria({'turma_ativa_id': 'turma-1'});
    await abrir(
      tester,
      api: api,
      notificador: notificador,
      preferencias: preferencias,
    );
    final turmasLidas = leiturasDeTurmas(api);

    notificador.receber(
      mensagem(
        turmaId: 'turma-2',
        tipo: 'atividade_nova',
        titulo: '☕ Cozinha & Prosa',
        corpo: 'Bia propôs: Noite de jogos',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('☕ Cozinha & Prosa\nBia propôs: Noite de jogos'),
      findsOneWidget,
    );
    expect(naPilula('Turma do Domingo'), findsOneWidget);
    expect(preferencias.valores['turma_ativa_id'], 'turma-1');
    expect(leiturasDeTurmas(api), turmasLidas + 1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a mensagem sem turma é ignorada, tocada ou com o app aberto', (
    tester,
  ) async {
    final api = apiComDuasTurmas();
    final notificador = NotificadorFalso();
    await abrir(tester, api: api, notificador: notificador);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    final turmasLidas = leiturasDeTurmas(api);

    notificador
      ..tocar(mensagem())
      ..receber(mensagem(corpo: 'Uma mensagem sem turma'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDoPerfil), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(leiturasDeTurmas(api), turmasLidas);
  });
}
