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
  Future<void> _garantirGoogle() => _inicializacao ??= _google.initialize();

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
    await _garantirGoogle();
    final GoogleSignInAccount conta;
    try {
      conta = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const ErroDeLogin('Login cancelado.', cancelado: true);
      }
      throw ErroDeLogin('Não consegui entrar com o Google (${e.code.name}).');
    }
    final idToken = conta.authentication.idToken;
    if (idToken == null) {
      throw const ErroDeLogin(
        'O Google não devolveu um token. Confira o SHA-1 no Firebase.',
      );
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<void> sair() async {
    await _auth.signOut();
    await _google.signOut();
  }
}
