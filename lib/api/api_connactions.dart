import 'modelos/alteracoes_do_eu.dart';
import 'modelos/atividade.dart';
import 'modelos/atividade_feita.dart';
import 'modelos/capa_do_diario.dart';
import 'modelos/comentario.dart';
import 'modelos/eu.dart';
import 'modelos/foto_para_enviar.dart';
import 'modelos/ideia.dart';
import 'modelos/pagina_da_comunidade.dart';
import 'modelos/pagina_do_diario.dart';
import 'modelos/perfil_de_pessoa.dart';
import 'modelos/pessoa.dart';
import 'modelos/proposta.dart';
import 'modelos/reacao.dart';
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

  /// GET /turmas/{id}/diario: encerradas, da mais recente para a mais antiga, cada uma com o resumo
  /// das reações e o total de comentários. A capa só vem na primeira página (sem `apos`).
  Future<PaginaDoDiario> listarDiario(
    String turmaId, {
    String? apos,
    int limite = 20,
  });

  /// PUT /atividades/{id}/reacoes/{tipo}: marca a reação (de novo não é erro) e devolve o resumo da
  /// atividade. 409 `atividade_aberta` se ela ainda não foi encerrada.
  Future<List<Reacao>> reagir(String atividadeId, TipoDeReacao tipo);

  /// DELETE /atividades/{id}/reacoes/{tipo}: tira a reação (tirar a que não está marcada não é erro).
  Future<List<Reacao>> desreagir(String atividadeId, TipoDeReacao tipo);

  /// GET /atividades/{id}/comentarios: do mais antigo para o mais novo.
  Future<PaginaDeComentarios> listarComentarios(
    String atividadeId, {
    String? apos,
    int limite = 50,
  });

  /// POST /atividades/{id}/comentarios. 422 com texto vazio ou acima de 500 caracteres.
  Future<Comentario> comentar(String atividadeId, String texto);

  /// DELETE /comentarios/{id}: só o autor (403 `sem_acesso` para outro membro).
  Future<void> apagarComentario(String comentarioId);

  /// PATCH /turmas/{id}/diario: só o que mudou; devolve a capa inteira.
  Future<CapaDoDiario> personalizarDiario(
    String turmaId,
    AlteracoesDaCapa alteracoes,
  );

  /// POST /turmas/{id}/embaralhar. 409 `ordem_travada` com atividade aberta.
  Future<TurmaDetalhe> embaralharOrdem(String turmaId);

  /// GET /turmas/{id}/ideias: o backlog, só as livres, da mais nova para a mais antiga.
  Future<List<Ideia>> listarIdeias(String turmaId);

  /// POST /turmas/{id}/ideias. 409 `backlog_cheio` com 5 livres do mesmo autor na turma.
  Future<Ideia> criarIdeia(
    String turmaId, {
    required String titulo,
    String descricao = '',
  });

  /// DELETE /ideias/{id}. 409 `ideia_indisponivel` quando um lançamento a usou antes.
  Future<void> apagarIdeia(String ideiaId);

  /// POST /comunidade/{id}/salvar. 409 `ja_no_backlog` / `backlog_cheio`; 404 quando a atividade
  /// saiu da Comunidade de quem pede.
  Future<Ideia> salvarDaComunidade(
    String atividadeId, {
    required String turmaId,
  });

  /// GET /comunidade: atividades de outras turmas, da mais recente para a mais antiga.
  Future<PaginaDaComunidade> listarComunidade({String? apos, int limite = 20});

  /// GET /conexoes: as minhas conexões, a mais recente primeiro.
  Future<List<Pessoa>> listarConexoes();

  /// POST /conexoes pelo código de amigo, sem aceite. `nova` sai do status: 201 quando a conexão
  /// nasceu agora, 200 quando já éramos conexão. O código de ninguém e o meu próprio são 422
  /// `codigo_invalido`, cada um com a sua mensagem.
  Future<({Pessoa pessoa, bool nova})> conectar(String codigo);

  /// DELETE /conexoes/{id}: desfaz para os dois lados; o que não existe não é erro.
  Future<void> desconectar(String usuarioId);

  /// POST /eu/codigo-de-amigo: o código antigo para de valer na hora, e as conexões ficam.
  Future<Eu> regenerarCodigoDeAmigo();

  /// GET /usuarios/{id}: o cabeçalho e os contadores, meus ou de uma conexão. 403 `sem_acesso` para
  /// quem não é conexão.
  Future<PerfilDePessoa> obterPerfil(String usuarioId);

  /// GET /usuarios/{id}/atividades: as feitas, da mais recente para a mais antiga. No perfil de outra
  /// pessoa, só as públicas e as das turmas de que sou membro; com a visibilidade dela desligada, 403
  /// `sem_acesso`.
  Future<PaginaDeAtividadesFeitas> listarAtividadesFeitas(
    String usuarioId, {
    String? apos,
    int limite = 20,
  });

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
