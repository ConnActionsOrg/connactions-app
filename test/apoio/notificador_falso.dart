import 'dart:async';

import 'package:connactions_app/app/notificador.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Dublê do FCM. As mensagens entram como o Firebase as entregaria e passam pela mesma conversão do
/// app, então a que chega sem turma some aqui como sumiria no aparelho.
class NotificadorFalso implements Notificador {
  NotificadorFalso({
    this.permissaoAtual = PermissaoDeAviso.concedida,
    this.permissaoAoPedir = PermissaoDeAviso.concedida,
    this.tokenAtual = 'token-fcm-1',
    this.mensagemAoAbrir,
  });

  /// O que o sistema responde sem perguntar nada. Concedida por padrão: o cartão do Feed só entra
  /// nos testes que são dele.
  PermissaoDeAviso permissaoAtual;

  /// O que a pessoa escolhe na caixa do sistema; passa a ser a [permissaoAtual].
  PermissaoDeAviso permissaoAoPedir;

  String? tokenAtual;
  Object? falhaAoLerToken;
  Object? falhaAoApagarToken;
  Object? falhaAoPedirPermissao;
  Object? falhaAoAbrirConfiguracoes;

  /// Prende o apagar do token, como o Firebase sem rede.
  Completer<void>? segurarApagarToken;

  /// O toque que abriu o app; entregue uma vez só, como o `getInitialMessage`.
  RemoteMessage? mensagemAoAbrir;

  final chamadas = <String>[];
  final _tokens = StreamController<String>.broadcast();
  final _toques = StreamController<RemoteMessage>.broadcast();
  final _recebidas = StreamController<RemoteMessage>.broadcast();

  /// O Firebase trocou o token deste aparelho.
  void renovarToken(String token) {
    tokenAtual = token;
    _tokens.add(token);
  }

  /// A pessoa tocou na notificação com o app em segundo plano.
  void tocar(RemoteMessage mensagem) => _toques.add(mensagem);

  /// A mensagem chegou com o app na frente.
  void receber(RemoteMessage mensagem) => _recebidas.add(mensagem);

  @override
  Future<PermissaoDeAviso> permissao() async {
    chamadas.add('permissao');
    return permissaoAtual;
  }

  @override
  Future<PermissaoDeAviso> pedirPermissao() async {
    chamadas.add('pedirPermissao');
    final falha = falhaAoPedirPermissao;
    if (falha != null) throw falha;
    return permissaoAtual = permissaoAoPedir;
  }

  @override
  Future<String?> token() async {
    chamadas.add('token');
    final falha = falhaAoLerToken;
    if (falha != null) throw falha;
    return tokenAtual;
  }

  @override
  Stream<String> get tokensNovos => _tokens.stream;

  @override
  Future<void> apagarToken() async {
    chamadas.add('apagarToken');
    final segurar = segurarApagarToken;
    if (segurar != null) await segurar.future;
    final falha = falhaAoApagarToken;
    if (falha != null) throw falha;
  }

  @override
  Future<Aviso?> tocadoAoAbrir() async {
    chamadas.add('tocadoAoAbrir');
    final mensagem = mensagemAoAbrir;
    mensagemAoAbrir = null;
    return mensagem == null ? null : avisoDaMensagem(mensagem);
  }

  @override
  Stream<Aviso> get tocados => avisosDasMensagens(_toques.stream);

  @override
  Stream<Aviso> get recebidosComAppAberto =>
      avisosDasMensagens(_recebidas.stream);

  @override
  Future<void> abrirConfiguracoes() async {
    chamadas.add('abrirConfiguracoes');
    final falha = falhaAoAbrirConfiguracoes;
    if (falha != null) throw falha;
  }
}
