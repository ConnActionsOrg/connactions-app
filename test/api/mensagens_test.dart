import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/mensagens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mensagemDoErro traduz cada falha para a tela', () {
    expect(
      mensagemDoErro(
        const ErroDaApi(status: 409, codigo: 'x', mensagem: 'Veio da API.'),
      ),
      'Veio da API.',
    );
    expect(
      mensagemDoErro(const ErroDeRede('caiu')),
      'Sem conexão com a API. Confira a rede e tente de novo.',
    );
    expect(
      mensagemDoErro(StateError('qualquer')),
      'Algo deu errado. Tente de novo.',
    );
  });
}
