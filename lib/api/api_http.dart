import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_connactions.dart';
import 'erro_da_api.dart';
import 'modelos/eu.dart';

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
  Future<Eu> atualizarVisibilidade({required bool visiveis}) async => Eu.deJson(
    await _enviar('PATCH', '/eu', corpo: {'atividades_visiveis': visiveis}),
  );

  Future<Map<String, dynamic>> _enviar(
    String metodo,
    String caminho, {
    Map<String, Object?>? corpo,
  }) async {
    final token = await _obterToken();
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

    final texto = await resposta.stream.bytesToString();
    final json = texto.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(texto) as Map<String, dynamic>;
    if (resposta.statusCode >= 400) {
      final erro = json['erro'] as Map<String, dynamic>?;
      throw ErroDaApi(
        status: resposta.statusCode,
        codigo: erro?['codigo'] as String? ?? 'erro_desconhecido',
        mensagem:
            erro?['mensagem'] as String? ?? 'Algo deu errado. Tente de novo.',
      );
    }
    return json;
  }
}
