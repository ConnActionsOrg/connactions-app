import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'autenticador.dart';

class AutenticadorFirebase implements Autenticador {
  AutenticadorFirebase({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _inicializacao;

  // Sem serverClientId de propósito: no Android o plugin lê o cliente web do google-services.json.
  // Se falhar, limpa a memoização: a próxima chamada tenta inicializar de novo.
  Future<void> _garantirGoogle() async {
    final inicializacao = _inicializacao ??= _google.initialize();
    try {
      await inicializacao;
    } catch (_) {
      _inicializacao = null;
      rethrow;
    }
  }

  @override
  Stream<ContaLogada?> get mudancas => _auth.authStateChanges().map(
    (u) => u == null
        ? null
        : ContaLogada(
            uid: u.uid,
            nome: u.displayName,
            email: u.email,
            fotoUrl: u.photoURL,
          ),
  );

  @override
  Future<String?> obterIdToken() async {
    final usuario = _auth.currentUser;
    return usuario?.getIdToken();
  }

  @override
  Future<void> entrarComGoogle() async {
    // Toda falha vira ErroDeLogin: a tela conhece só esta interface, nunca tipos do Firebase/Google.
    try {
      await _garantirGoogle();
      final conta = await _google.authenticate();
      final idToken = conta.authentication.idToken;
      if (idToken == null) {
        throw const ErroDeLogin(
          'O Google não devolveu um token. Confira o SHA-1 no Firebase.',
        );
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const ErroDeLogin('Login cancelado.', cancelado: true);
      }
      throw const ErroDeLogin(
        'Não consegui entrar com o Google. Tente de novo.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const ErroDeLogin('Sem conexão. Confira a rede e tente de novo.');
      }
      throw const ErroDeLogin(
        'Não consegui entrar com o Google. Tente de novo.',
      );
    }
  }

  @override
  Future<void> sair() async {
    // Mesmo se o Google não inicializar, o sign-out do Firebase é o que derruba a sessão do app.
    try {
      await _garantirGoogle();
    } finally {
      await _auth.signOut();
    }
    await _google.signOut();
  }
}
