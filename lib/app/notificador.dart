import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

/// Dois estados bastam: "nunca perguntado" e "recusado" dão no mesmo para o app, e quem sabe se ele
/// já perguntou é a preferência `notificacoes_perguntadas`.
enum PermissaoDeAviso { concedida, negada }

/// O que o app usa de uma mensagem do FCM: a turma diz o que abrir e o que reler; título e corpo
/// vão para o aviso na tela quando o app está aberto.
class Aviso {
  const Aviso({
    required this.tipo,
    required this.turmaId,
    this.atividadeId,
    required this.titulo,
    required this.corpo,
  });

  /// `sua_vez`, `atividade_nova`, `registro_novo` ou `prazo`.
  final String tipo;
  final String turmaId;

  /// Nulo no "sua vez" que nasce de uma saída da turma sem atividade aberta.
  final String? atividadeId;
  final String titulo;
  final String corpo;
}

/// Fronteira com o FCM e com as configurações de notificação do Android. As telas só conhecem
/// esta interface.
abstract class Notificador {
  Future<PermissaoDeAviso> permissao();

  /// A caixa do sistema no Android 13+; antes dele, só lê o estado.
  Future<PermissaoDeAviso> pedirPermissao();

  /// O token de registro do FCM deste aparelho; `null` enquanto o Firebase não tem um.
  Future<String?> token();

  Stream<String> get tokensNovos;

  /// Invalida o token no Firebase: nada mais chega a ele, mesmo que a API ainda o guarde.
  Future<void> apagarToken();

  /// O toque que abriu o app a frio; `null` se ele abriu de outro jeito.
  Future<Aviso?> tocadoAoAbrir();

  /// Toques com o app em segundo plano.
  Stream<Aviso> get tocados;

  /// Com o app na frente o sistema não mostra nada: quem mostra é o app.
  Stream<Aviso> get recebidosComAppAberto;

  /// As configurações de notificação do app, para quando o Android não mostra mais a caixa.
  Future<void> abrirConfiguracoes();
}

/// `null` quando a mensagem não diz de que turma é: sem ela não há o que abrir nem o que reler.
Aviso? avisoDaMensagem(RemoteMessage mensagem) {
  final dados = mensagem.data;
  final turmaId = dados['turma_id'];
  if (turmaId is! String || turmaId.isEmpty) return null;
  final tipo = dados['tipo'];
  final atividadeId = dados['atividade_id'];
  return Aviso(
    tipo: tipo is String ? tipo : '',
    turmaId: turmaId,
    atividadeId: atividadeId is String && atividadeId.isNotEmpty
        ? atividadeId
        : null,
    titulo: mensagem.notification?.title ?? '',
    corpo: mensagem.notification?.body ?? '',
  );
}

/// Só as mensagens que viram [Aviso]; as outras param aqui.
Stream<Aviso> avisosDasMensagens(Stream<RemoteMessage> mensagens) => mensagens
    .map(avisoDaMensagem)
    .where((aviso) => aviso != null)
    .cast<Aviso>();

/// `notDetermined` e `deniedPermanently` também são negada: o que muda entre eles é se o Android
/// ainda mostra a caixa, e isso só o pedido descobre.
PermissaoDeAviso permissaoDoStatus(AuthorizationStatus status) =>
    switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PermissaoDeAviso.concedida,
      AuthorizationStatus.denied ||
      AuthorizationStatus.notDetermined ||
      AuthorizationStatus.deniedPermanently => PermissaoDeAviso.negada,
    };

class NotificadorFirebase implements Notificador {
  NotificadorFirebase({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  // a outra ponta mora na MainActivity
  static const _canal = MethodChannel('connactions/notificacoes');

  @override
  Future<PermissaoDeAviso> permissao() async => permissaoDoStatus(
    (await _messaging.getNotificationSettings()).authorizationStatus,
  );

  @override
  Future<PermissaoDeAviso> pedirPermissao() async => permissaoDoStatus(
    (await _messaging.requestPermission()).authorizationStatus,
  );

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> get tokensNovos => _messaging.onTokenRefresh;

  @override
  Future<void> apagarToken() => _messaging.deleteToken();

  @override
  Future<Aviso?> tocadoAoAbrir() async {
    final mensagem = await _messaging.getInitialMessage();
    return mensagem == null ? null : avisoDaMensagem(mensagem);
  }

  @override
  Stream<Aviso> get tocados =>
      avisosDasMensagens(FirebaseMessaging.onMessageOpenedApp);

  @override
  Stream<Aviso> get recebidosComAppAberto =>
      avisosDasMensagens(FirebaseMessaging.onMessage);

  @override
  Future<void> abrirConfiguracoes() =>
      _canal.invokeMethod<void>('abrirConfiguracoes');
}
