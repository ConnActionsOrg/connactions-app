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
