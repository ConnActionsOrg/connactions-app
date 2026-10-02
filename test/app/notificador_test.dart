import 'dart:async';

import 'package:connactions_app/app/notificador.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'lê tipo, turma e atividade dos dados, e título e corpo da notificação',
    () {
      final aviso = avisoDaMensagem(
        const RemoteMessage(
          data: {
            'tipo': 'registro_novo',
            'turma_id': 'turma-1',
            'atividade_id': 'ativ-1',
          },
          notification: RemoteNotification(
            title: '🌿 Turma do Domingo',
            body: 'Bia postou um registro em Piquenique',
          ),
        ),
      );

      expect(aviso, isNotNull);
      expect(aviso!.tipo, 'registro_novo');
      expect(aviso.turmaId, 'turma-1');
      expect(aviso.atividadeId, 'ativ-1');
      expect(aviso.titulo, '🌿 Turma do Domingo');
      expect(aviso.corpo, 'Bia postou um registro em Piquenique');
    },
  );

  test('o "sua vez" de uma saída da turma chega sem atividade', () {
    final aviso = avisoDaMensagem(
      const RemoteMessage(
        data: {'tipo': 'sua_vez', 'turma_id': 'turma-1'},
        notification: RemoteNotification(
          title: 'É a sua vez de propor!',
          body: '🌿 Turma do Domingo: Bia saiu da turma.',
        ),
      ),
    );

    expect(aviso?.turmaId, 'turma-1');
    expect(aviso?.atividadeId, isNull);
  });

  test('sem turma_id a mensagem não vira Aviso', () {
    expect(
      avisoDaMensagem(
        const RemoteMessage(
          data: {'tipo': 'sua_vez'},
          notification: RemoteNotification(title: 'É a sua vez de propor!'),
        ),
      ),
      isNull,
    );
    expect(
      avisoDaMensagem(
        const RemoteMessage(data: {'tipo': 'sua_vez', 'turma_id': ''}),
      ),
      isNull,
    );
  });

  test('avisosDasMensagens deixa passar só as mensagens com turma', () async {
    final mensagens = StreamController<RemoteMessage>();
    final avisos = avisosDasMensagens(mensagens.stream).toList();

    mensagens
      ..add(const RemoteMessage(data: {'tipo': 'prazo'}))
      ..add(
        const RemoteMessage(data: {'tipo': 'prazo', 'turma_id': 'turma-2'}),
      );
    await mensagens.close();

    expect((await avisos).map((a) => a.turmaId), ['turma-2']);
  });

  test('authorized e provisional são concedida; os outros três, negada', () {
    const esperado = {
      AuthorizationStatus.authorized: PermissaoDeAviso.concedida,
      AuthorizationStatus.provisional: PermissaoDeAviso.concedida,
      AuthorizationStatus.denied: PermissaoDeAviso.negada,
      // no Android 13+ é o "nunca perguntado"
      AuthorizationStatus.notDetermined: PermissaoDeAviso.negada,
      AuthorizationStatus.deniedPermanently: PermissaoDeAviso.negada,
    };
    for (final MapEntry(key: status, value: permissao) in esperado.entries) {
      expect(permissaoDoStatus(status), permissao, reason: '$status');
    }
    expect(esperado.keys, containsAll(AuthorizationStatus.values));
  });
}
