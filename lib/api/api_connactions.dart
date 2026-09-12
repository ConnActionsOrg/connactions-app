import 'modelos/eu.dart';

/// Tudo que o app pede à API, uma operação por método. A implementação real fala HTTP; os testes
/// injetam um FakeApi com a mesma cara.
abstract class ApiConnactions {
  /// POST /eu: cria o perfil no primeiro login ou devolve o existente.
  Future<Eu> criarEu();

  /// GET /eu. Lança ErroDaApi com `perfilNaoCriado` se ainda não há perfil.
  Future<Eu> obterEu();

  /// PATCH /eu com atividades_visiveis.
  Future<Eu> atualizarVisibilidade({required bool visiveis});
}
