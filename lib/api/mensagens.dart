import 'erro_da_api.dart';

/// Texto para a tela a partir de qualquer falha. A API já manda a mensagem pronta; o resto é nosso.
String mensagemDoErro(Object erro) => switch (erro) {
  ErroDaApi(:final mensagem) => mensagem,
  ErroDeRede() => 'Sem conexão com a API. Confira a rede e tente de novo.',
  _ => 'Algo deu errado. Tente de novo.',
};
