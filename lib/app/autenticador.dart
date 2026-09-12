/// Quem está logado no provedor de identidade. Só o que a sessão precisa; o perfil vem da API.
class ContaLogada {
  const ContaLogada({required this.uid, this.nome, this.email, this.fotoUrl});

  final String uid;
  final String? nome;
  final String? email;
  final String? fotoUrl;
}

class ErroDeLogin implements Exception {
  const ErroDeLogin(this.mensagem, {this.cancelado = false});

  final String mensagem;
  final bool cancelado;

  @override
  String toString() => 'ErroDeLogin($mensagem)';
}

/// Fronteira com o Firebase Auth e o Google Sign-In. O app só conhece esta interface; o Firebase
/// mora numa implementação e os testes usam um dublê.
abstract class Autenticador {
  /// Emite a conta atual ao ser ouvido e a cada troca. `null` é deslogado.
  Stream<ContaLogada?> get mudancas;

  /// ID token para a API, renovado pelo SDK quando vence. `null` se deslogado.
  Future<String?> obterIdToken();

  Future<void> entrarComGoogle();

  Future<void> sair();
}
