import 'modelos/alteracoes_do_eu.dart';
import 'modelos/atividade.dart';
import 'modelos/eu.dart';
import 'modelos/foto_para_enviar.dart';
import 'modelos/pagina_do_diario.dart';
import 'modelos/proposta.dart';
import 'modelos/registro.dart';
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

  /// GET /turmas/{id}/atividade-aberta: a aberta com os registros, ou null quando não há.
  Future<Atividade?> obterAtividadeAberta(String turmaId);

  /// POST /turmas/{id}/atividades. 409 `nao_e_sua_vez` / `atividade_ja_aberta`.
  Future<Atividade> lancarAtividade(String turmaId, Proposta proposta);

  /// POST /atividades/{id}/encerrar: a atividade fechada e a turma já com a vez nova.
  Future<Encerramento> encerrarAtividade(String atividadeId);

  /// POST /atividades/{id}/registros (multipart). 409 pelas regras de formato, 422 `foto_invalida`.
  Future<Registro> registrar(
    String atividadeId, {
    required FotoParaEnviar foto,
    String legenda = '',
  });

  /// DELETE /registros/{id}.
  Future<void> apagarRegistro(String registroId);

  /// GET /turmas/{id}/diario: encerradas, da mais recente para a mais antiga.
  Future<PaginaDoDiario> listarDiario(
    String turmaId, {
    String? apos,
    int limite = 20,
  });

  /// POST /turmas/{id}/embaralhar. 409 `ordem_travada` com atividade aberta.
  Future<TurmaDetalhe> embaralharOrdem(String turmaId);

  /// PUT /eu/foto (multipart).
  Future<Eu> trocarFoto(FotoParaEnviar foto);

  /// PUT /dispositivos: o aparelho passa a ser de quem está logado, mesmo que fosse de outra conta.
  Future<void> registrarDispositivo({
    required String token,
    required String plataforma,
  });

  /// DELETE /dispositivos/{token}: 204 sempre; a API só apaga se o aparelho for de quem chamou.
  Future<void> removerDispositivo(String token);
}
