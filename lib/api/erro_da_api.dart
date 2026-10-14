/// Resposta de erro da API, já no formato do contrato: código estável e mensagem pronta para a tela.
class ErroDaApi implements Exception {
  const ErroDaApi({
    required this.status,
    required this.codigo,
    required this.mensagem,
  });

  final int status;
  final String codigo;
  final String mensagem;

  bool get perfilNaoCriado => codigo == 'perfil_nao_criado';
  bool get naoAutenticado => status == 401;
  bool get codigoInvalido => codigo == 'codigo_invalido';
  bool get handleEmUso => codigo == 'handle_em_uso';
  bool get semAcesso => codigo == 'sem_acesso';
  bool get naoEncontrado => codigo == 'nao_encontrado';
  bool get naoESuaVez => codigo == 'nao_e_sua_vez';
  bool get atividadeJaAberta => codigo == 'atividade_ja_aberta';
  bool get atividadeEncerrada => codigo == 'atividade_encerrada';
  bool get jaRegistrou => codigo == 'ja_registrou';
  bool get limiteDeFotos => codigo == 'limite_de_fotos';
  bool get soOProponenteRegistra => codigo == 'so_o_proponente_registra';
  bool get ordemTravada => codigo == 'ordem_travada';
  bool get fotoInvalida => codigo == 'foto_invalida';
  bool get backlogCheio => codigo == 'backlog_cheio';
  bool get jaNoBacklog => codigo == 'ja_no_backlog';
  bool get ideiaIndisponivel => codigo == 'ideia_indisponivel';
  bool get atividadeAberta => codigo == 'atividade_aberta';

  /// Qualquer 409: o estado mudou embaixo de mim (a vez passou, alguém encerrou, já postei em outro
  /// aparelho). As telas avisam, recarregam e voltam.
  bool get conflito => status == 409;

  @override
  String toString() => 'ErroDaApi($status $codigo: $mensagem)';
}

/// A requisição nem chegou a uma resposta: sem rede, API fora, tempo esgotado.
class ErroDeRede implements Exception {
  const ErroDeRede(this.causa);

  final Object causa;

  @override
  String toString() => 'ErroDeRede($causa)';
}
