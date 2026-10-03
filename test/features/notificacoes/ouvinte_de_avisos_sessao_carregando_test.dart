import 'dart:async';

import 'package:connactions_app/app/autenticador.dart';
import 'package:connactions_app/features/entrada/tela_de_abertura.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:connactions_app/features/turmas/seletor_de_turma.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/autenticador_falso.dart';
import '../../apoio/erros_sem_dono.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/notificador_falso.dart';
import '../../apoio/preferencias_em_memoria.dart';

/// Sessão que só resolve quando o teste mandar: o toque a frio chega com a conta ainda carregando.
class _AutenticadorLento extends AutenticadorFalso {
  final liberar = Completer<ContaLogada?>();

  @override
  Stream<ContaLogada?> get mudancas => Stream.fromFuture(liberar.future);
}

RemoteMessage mensagem() => RemoteMessage(
  data: {'tipo': 'sua_vez', 'turma_id': 'turma-2'},
  notification: RemoteNotification(
    title: 'É a sua vez de propor!',
    body: '☕ Cozinha & Prosa: Bia encerrou a rodada 1.',
  ),
);

FakeApi apiComDuasTurmas() => FakeApi(
  eu: euDeTeste(),
  turmas: [
    turmaDeTeste(id: 'turma-1'),
    turmaDeTeste(id: 'turma-2', nome: 'Cozinha & Prosa', emoji: '☕'),
  ],
);

void main() {
  testWidgets(
    'toque a frio com a sessão carregando, depois logada: Feed da turma do aviso',
    (tester) async {
      final autenticador = _AutenticadorLento();
      final notificador = NotificadorFalso()..mensagemAoAbrir = mensagem();
      final preferencias = PreferenciasEmMemoria({'turma_ativa_id': 'turma-1'});

      final soltos = await errosSemDono(() async {
        await tester.pumpWidget(
          appDeTeste(
            api: apiComDuasTurmas(),
            notificador: notificador,
            preferencias: preferencias,
            autenticador: autenticador,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // a sessão ainda carrega: abertura, e o toque já foi consumido
        expect(notificador.chamadas, contains('tocadoAoAbrir'));
        expect(find.byType(TelaDeAbertura), findsOneWidget);
        expect(find.byType(TelaDoFeed), findsNothing);

        autenticador.liberar.complete(contaDeTeste);
        await tester.pumpAndSettle();
      });

      expect(soltos, isEmpty);
      expect(find.byType(TelaDoFeed), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SeletorDeTurma),
          matching: find.text('Cozinha & Prosa'),
        ),
        findsOneWidget,
      );
      expect(preferencias.valores['turma_ativa_id'], 'turma-2');
    },
  );

  testWidgets(
    'toque a frio com a sessão carregando, depois deslogada: entrada',
    (tester) async {
      final autenticador = _AutenticadorLento();
      final notificador = NotificadorFalso()..mensagemAoAbrir = mensagem();

      final soltos = await errosSemDono(() async {
        await tester.pumpWidget(
          appDeTeste(
            api: apiComDuasTurmas(),
            notificador: notificador,
            autenticador: autenticador,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(notificador.chamadas, contains('tocadoAoAbrir'));
        expect(find.byType(TelaDeAbertura), findsOneWidget);

        autenticador.liberar.complete(null);
        await tester.pumpAndSettle();
      });

      expect(soltos, isEmpty);
      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.byType(TelaDoFeed), findsNothing);
    },
  );
}
