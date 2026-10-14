import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_connactions.dart';
import 'erro_da_api.dart';
import 'modelos/alteracoes_do_eu.dart';
import 'modelos/atividade.dart';
import 'modelos/capa_do_diario.dart';
import 'modelos/comentario.dart';
import 'modelos/eu.dart';
import 'modelos/foto_para_enviar.dart';
import 'modelos/ideia.dart';
import 'modelos/pagina_da_comunidade.dart';
import 'modelos/pagina_do_diario.dart';
import 'modelos/proposta.dart';
import 'modelos/reacao.dart';
import 'modelos/registro.dart';
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
  // upload no 4G: o tempo limite do JSON (15 s) cortaria a foto pela metade
  static const _tempoLimiteDoUpload = Duration(seconds: 60);

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

  @override
  Future<Atividade?> obterAtividadeAberta(String turmaId) async {
    final json = await _enviar('GET', '/turmas/$turmaId/atividade-aberta');
    final atividade = json['atividade'];
    return atividade == null
        ? null
        : Atividade.deJson(atividade as Map<String, dynamic>);
  }

  @override
  Future<Atividade> lancarAtividade(String turmaId, Proposta proposta) async =>
      Atividade.deJson(
        await _enviar(
          'POST',
          '/turmas/$turmaId/atividades',
          corpo: proposta.toJson(),
        ),
      );

  @override
  Future<Encerramento> encerrarAtividade(String atividadeId) async =>
      Encerramento.deJson(
        await _enviar('POST', '/atividades/$atividadeId/encerrar'),
      );

  @override
  Future<Registro> registrar(
    String atividadeId, {
    required FotoParaEnviar foto,
    String legenda = '',
  }) async => Registro.deJson(
    await _enviarMultipart(
      'POST',
      '/atividades/$atividadeId/registros',
      foto: foto,
      campos: {'legenda': legenda},
    ),
  );

  @override
  Future<void> apagarRegistro(String registroId) async {
    await _enviar('DELETE', '/registros/$registroId');
  }

  @override
  Future<PaginaDoDiario> listarDiario(
    String turmaId, {
    String? apos,
    int limite = 20,
  }) async => PaginaDoDiario.deJson(
    await _enviar(
      'GET',
      '/turmas/$turmaId/diario',
      consulta: {'apos': ?apos, 'limite': '$limite'},
    ),
  );

  @override
  Future<List<Reacao>> reagir(String atividadeId, TipoDeReacao tipo) async =>
      _reacoes(
        await _enviar('PUT', '/atividades/$atividadeId/reacoes/${tipo.slug}'),
      );

  @override
  Future<List<Reacao>> desreagir(String atividadeId, TipoDeReacao tipo) async =>
      _reacoes(
        await _enviar(
          'DELETE',
          '/atividades/$atividadeId/reacoes/${tipo.slug}',
        ),
      );

  List<Reacao> _reacoes(Map<String, dynamic> json) =>
      Reacao.listaDeJson(json['reacoes'] as List<dynamic>);

  @override
  Future<PaginaDeComentarios> listarComentarios(
    String atividadeId, {
    String? apos,
    int limite = 50,
  }) async => PaginaDeComentarios.deJson(
    await _enviar(
      'GET',
      '/atividades/$atividadeId/comentarios',
      consulta: {'apos': ?apos, 'limite': '$limite'},
    ),
  );

  @override
  Future<Comentario> comentar(String atividadeId, String texto) async =>
      Comentario.deJson(
        await _enviar(
          'POST',
          '/atividades/$atividadeId/comentarios',
          corpo: {'texto': texto},
        ),
      );

  @override
  Future<void> apagarComentario(String comentarioId) async {
    // 204 sem corpo: o _enviar devolve {} e não há nada a ler
    await _enviar('DELETE', '/comentarios/$comentarioId');
  }

  @override
  Future<CapaDoDiario> personalizarDiario(
    String turmaId,
    AlteracoesDaCapa alteracoes,
  ) async => CapaDoDiario.deJson(
    await _enviar(
      'PATCH',
      '/turmas/$turmaId/diario',
      corpo: alteracoes.toJson(),
    ),
  );

  @override
  Future<TurmaDetalhe> embaralharOrdem(String turmaId) async =>
      TurmaDetalhe.deJson(await _enviar('POST', '/turmas/$turmaId/embaralhar'));

  @override
  Future<List<Ideia>> listarIdeias(String turmaId) async {
    final json = await _enviar('GET', '/turmas/$turmaId/ideias');
    return (json['itens'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Ideia.deJson)
        .toList();
  }

  @override
  Future<Ideia> criarIdeia(
    String turmaId, {
    required String titulo,
    String descricao = '',
  }) async => Ideia.deJson(
    await _enviar(
      'POST',
      '/turmas/$turmaId/ideias',
      corpo: {'titulo': titulo, 'descricao': descricao},
    ),
  );

  @override
  Future<void> apagarIdeia(String ideiaId) async {
    await _enviar('DELETE', '/ideias/$ideiaId');
  }

  @override
  Future<Ideia> salvarDaComunidade(
    String atividadeId, {
    required String turmaId,
  }) async => Ideia.deJson(
    await _enviar(
      'POST',
      '/comunidade/$atividadeId/salvar',
      corpo: {'turma_id': turmaId},
    ),
  );

  @override
  Future<PaginaDaComunidade> listarComunidade({
    String? apos,
    int limite = 20,
  }) async => PaginaDaComunidade.deJson(
    await _enviar(
      'GET',
      '/comunidade',
      consulta: {'apos': ?apos, 'limite': '$limite'},
    ),
  );

  @override
  Future<Eu> trocarFoto(FotoParaEnviar foto) async =>
      Eu.deJson(await _enviarMultipart('PUT', '/eu/foto', foto: foto));

  @override
  Future<void> registrarDispositivo({
    required String token,
    required String plataforma,
  }) async {
    await _enviar(
      'PUT',
      '/dispositivos',
      corpo: {'token': token, 'plataforma': plataforma},
    );
  }

  @override
  Future<void> removerDispositivo(String token) async {
    // segmento de caminho, não componente: o ':' do token do FCM vai literal, e um '/' viraria %2F
    // em vez de partir a rota
    await _enviar(
      'DELETE',
      '/${Uri(pathSegments: ['dispositivos', token]).path}',
    );
  }

  Future<Map<String, dynamic>> _enviar(
    String metodo,
    String caminho, {
    Map<String, Object?>? corpo,
    Map<String, String>? consulta,
  }) {
    final url = Uri.parse('$_base$caminho');
    final requisicao = http.Request(
      metodo,
      consulta == null ? url : url.replace(queryParameters: consulta),
    );
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json; charset=utf-8';
      requisicao.body = jsonEncode(corpo);
    }
    return _despachar(requisicao);
  }

  Future<Map<String, dynamic>> _enviarMultipart(
    String metodo,
    String caminho, {
    required FotoParaEnviar foto,
    Map<String, String> campos = const {},
  }) {
    final requisicao =
        http.MultipartRequest(metodo, Uri.parse('$_base$caminho'))
          ..fields.addAll(campos)
          ..files.add(
            http.MultipartFile.fromBytes(
              'foto',
              foto.bytes,
              filename: foto.nome,
            ),
          );
    return _despachar(requisicao, tempoLimite: _tempoLimiteDoUpload);
  }

  Future<Map<String, dynamic>> _despachar(
    http.BaseRequest requisicao, {
    Duration tempoLimite = _tempoLimite,
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
    requisicao.headers['Authorization'] = 'Bearer $token';
    requisicao.headers['Accept'] = 'application/json';

    final http.StreamedResponse resposta;
    try {
      resposta = await _cliente.send(requisicao).timeout(tempoLimite);
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
