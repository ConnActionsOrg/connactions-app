import 'package:connactions_app/api/erro_da_api.dart';
import 'package:flutter_test/flutter_test.dart';

ErroDaApi erro(int status, String codigo) =>
    ErroDaApi(status: status, codigo: codigo, mensagem: 'm');

void main() {
  test('getters dos códigos de atividade, registro e foto', () {
    expect(erro(409, 'nao_e_sua_vez').naoESuaVez, isTrue);
    expect(erro(409, 'atividade_ja_aberta').atividadeJaAberta, isTrue);
    expect(erro(409, 'atividade_encerrada').atividadeEncerrada, isTrue);
    expect(erro(409, 'ja_registrou').jaRegistrou, isTrue);
    expect(erro(409, 'limite_de_fotos').limiteDeFotos, isTrue);
    expect(erro(409, 'so_o_proponente_registra').soOProponenteRegistra, isTrue);
    expect(erro(409, 'ordem_travada').ordemTravada, isTrue);
    expect(erro(422, 'foto_invalida').fotoInvalida, isTrue);
    expect(erro(422, 'foto_invalida').conflito, isFalse);
  });

  test('conflito é qualquer 409: o estado mudou embaixo de mim', () {
    expect(erro(409, 'qualquer').conflito, isTrue);
    expect(erro(403, 'sem_acesso').conflito, isFalse);
  });
}
