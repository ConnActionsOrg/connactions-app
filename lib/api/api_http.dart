import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_connactions.dart';
import 'erro_da_api.dart';
import 'modelos/alteracoes_do_eu.dart';
import 'modelos/eu.dart';
import 'modelos/turma.dart';

typedef ObterToken = Future<String?> Function();

/// Cliente HTTP da API. Anexa o ID token do Firebase e traduz o envelope de erro do contrato.
class ApiHttp implements ApiConnactions {
  ApiHttp({required Uri base, required this._obterToken, http.Client? cliente})
    : _base = base.toString().replaceAll(RegExp(r'/+$'), ''),
      _cliente = cliente ?? http.Client();

  final String _base;
  final ObterToken _obterToken;
  final http.Client _cliente;

  static const _tempoLimite = Duration(seconds: 15);

  @override
  Future<Eu> criarEu() async => Eu.deJson(await _enviar('POST', '/eu'));

  @override
  Future<Eu> obterEu() async => Eu.deJson(await _enviar('GET', '/eu'));

  @override
  Future<Eu> atualizarEu(AlteracoesDoEu alteracoes) async =>
      Eu.deJson(await _enviar('PATCH', '/eu', corpo: alteracoes.toJson()));

  @override
  Future<List<Turma>> listarTurmas() async {
    final json = await _enviar('GET', '/turmas');
    return (json['itens'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Turma.deJson)
        .toList();
  }

  @override
  Future<Turma> criarTurma({
    required String nome,
    required String emoji,
  }) async => Turma.deJson(
    await _enviar('POST', '/turmas', corpo: {'nome': nome, 'emoji': emoji}),
  );

  @override
  Future<Turma> entrarNaTurma({required String codigo}) async => Turma.deJson(
    await _enviar('POST', '/turmas/entrar', corpo: {'codigo': codigo}),
  );

  @override
  Future<TurmaDetalhe> obterTurma(String id) async =>
      TurmaDetalhe.deJson(await _enviar('GET', '/turmas/$id'));

  @override
  Future<Turma> regenerarConvite(String id) async =>
      Turma.deJson(await _enviar('POST', '/turmas/$id/convite'));

  @override
  Future<void> sairDaTurma(String id) async {
    // 204 sem corpo: o _enviar devolve {} e não há nada a ler
    await _enviar('DELETE', '/turmas/$id/membros/eu');
  }

  Future<Map<String, dynamic>> _enviar(
    String metodo,
    String caminho, {
    Map<String, Object?>? corpo,
  }) async {
    final String? token;
    try {
      token = await _obterToken();
    } on Exception catch (e) {
      throw ErroDeRede(e);
    }
    if (token == null) {
      throw const ErroDaApi(
        status: 401,
        codigo: 'nao_autenticado',
        mensagem: 'Entre para continuar.',
      );
    }
    final requisicao = http.Request(metodo, Uri.parse('$_base$caminho'))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json; charset=utf-8';
      requisicao.body = jsonEncode(corpo);
    }

    final http.StreamedResponse resposta;
    try {
      resposta = await _cliente.send(requisicao).timeout(_tempoLimite);
    } on Exception catch (e) {
      throw ErroDeRede(e);
    }

    final String texto;
    try {
      texto = await resposta.stream.bytesToString();
    } on Exception catch (e) {
      throw ErroDeRede(e);
    }
    final json = _decodificarEnvelope(texto);
    if (json == null) {
      final falha = resposta.statusCode >= 400;
      throw ErroDaApi(
        status: resposta.statusCode,
        codigo: falha ? 'erro_desconhecido' : 'resposta_invalida',
        mensagem: falha
            ? 'Algo deu errado. Tente de novo.'
            : 'A API respondeu de um jeito inesperado. Tente de novo.',
      );
    }
    if (resposta.statusCode >= 400) {
      final erro = json['erro'];
      final envelope = erro is Map<String, dynamic> ? erro : null;
      throw ErroDaApi(
        status: resposta.statusCode,
        codigo: envelope?['codigo'] as String? ?? 'erro_desconhecido',
        mensagem:
            envelope?['mensagem'] as String? ??
            'Algo deu errado. Tente de novo.',
      );
    }
    return json;
  }

  /// `null` quando o corpo não é um objeto JSON válido: JSON inválido, ou JSON válido que não é
  /// um objeto (lista, string, número). Corpo vazio é `{}`, não falha.
  Map<String, dynamic>? _decodificarEnvelope(String texto) {
    if (texto.isEmpty) return <String, dynamic>{};
    try {
      final decodificado = jsonDecode(texto);
      return decodificado is Map<String, dynamic> ? decodificado : null;
    } on FormatException {
      return null;
    }
  }
}
