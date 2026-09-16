import 'modelos/alteracoes_do_eu.dart';
import 'modelos/eu.dart';
import 'modelos/turma.dart';

/// Tudo que o app pede à API, uma operação por método. A implementação real fala HTTP; os testes
/// injetam um FakeApi com a mesma cara.
abstract class ApiConnactions {
  /// POST /eu: cria o perfil no primeiro login ou devolve o existente.
  Future<Eu> criarEu();

  /// GET /eu. Lança ErroDaApi com `perfilNaoCriado` se ainda não há perfil.
  Future<Eu> obterEu();

  /// PATCH /eu com o que mudou (nome, handle, bio, atividades_visiveis).
  Future<Eu> atualizarEu(AlteracoesDoEu alteracoes);

  /// GET /turmas: as minhas turmas, na ordem em que entrei.
  Future<List<Turma>> listarTurmas();

  /// POST /turmas.
  Future<Turma> criarTurma({required String nome, required String emoji});

  /// POST /turmas/entrar. Devolve a turma tanto se entrei (201) quanto se já era membro (200).
  /// Lança ErroDaApi com `codigoInvalido` se o código não existe.
  Future<Turma> entrarNaTurma({required String codigo});

  /// GET /turmas/{id}, com os membros por ordem.
  Future<TurmaDetalhe> obterTurma(String id);

  /// POST /turmas/{id}/convite: código novo, o antigo morre.
  Future<Turma> regenerarConvite(String id);

  /// DELETE /turmas/{id}/membros/eu.
  Future<void> sairDaTurma(String id);
}
