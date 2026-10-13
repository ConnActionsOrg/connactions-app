import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connactions_app/api/api_connactions.dart';
import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/alteracoes_do_eu.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/api/modelos/eu.dart';
import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/api/modelos/pagina_da_comunidade.dart';
import 'package:connactions_app/api/modelos/pagina_do_diario.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/api/modelos/proposta.dart';
import 'package:connactions_app/api/modelos/registro.dart';
import 'package:connactions_app/api/modelos/turma.dart';

/// Dublê da API em memória. Registra as chamadas para os testes afirmarem o que o app pediu.
class FakeApi implements ApiConnactions {
  FakeApi({
    Eu? eu,
    List<Turma> turmas = const [],
    Map<String, List<Membro>> membrosPor = const {},
    Map<String, Turma> convites = const {},
    Map<String, Atividade?> abertaPor = const {},
    Map<String, List<Atividade>> diarioPor = const {},
    Map<String, List<Ideia>> ideiasPor = const {},
    List<AtividadeDaComunidade> comunidade = const [],
    this.falhaAoObter,
    this.falhaAoAtualizar,
    this.falhaAoListarTurmas,
    this.falhaAoCriarTurma,
    this.falhaAoEntrar,
    this.falhaAoObterTurma,
    this.falhaAoRegenerar,
    this.falhaAoSair,
    this.falhaAoObterAberta,
    this.falhaAoLancar,
    this.falhaAoEncerrar,
    this.falhaAoRegistrar,
    this.falhaAoApagarRegistro,
    this.falhaAoListarDiario,
    this.falhaAoEmbaralhar,
    this.falhaAoTrocarFoto,
    this.falhaAoRegistrarDispositivo,
    this.falhaAoRemoverDispositivo,
    this.falhaAoListarIdeias,
    this.falhaAoCriarIdeia,
    this.falhaAoApagarIdeia,
    this.falhaAoSalvarDaComunidade,
    this.falhaAoListarComunidade,
  }) : _eu = eu, // ignore: prefer_initializing_formals
       turmas = List.of(turmas),
       membrosPor = {
         for (final e in membrosPor.entries) e.key: List.of(e.value),
       },
       convites = Map.of(convites),
       abertaPor = Map.of(abertaPor),
       diarioPor = {for (final e in diarioPor.entries) e.key: List.of(e.value)},
       ideiasPor = {for (final e in ideiasPor.entries) e.key: List.of(e.value)},
       comunidade = List.of(comunidade);

  Eu? _eu;

  /// Minhas turmas (o que GET /turmas devolve). Criar, entrar e sair mexem aqui.
  final List<Turma> turmas;

  /// Membros por id de turma. Sem entrada, a turma tem só a mim.
  final Map<String, List<Membro>> membrosPor;

  /// Turmas de outras pessoas que aceitam o meu "entrar", pelo código.
  final Map<String, Turma> convites;

  /// A atividade aberta por id de turma; ausente ou nula = sem aberta.
  final Map<String, Atividade?> abertaPor;

  /// Encerradas por id de turma, da mais recente para a mais antiga.
  final Map<String, List<Atividade>> diarioPor;

  /// As ideias livres por id de turma, da mais nova para a mais antiga.
  final Map<String, List<Ideia>> ideiasPor;

  /// O que a Comunidade mostra para mim (a API já tira as turmas de que sou membro).
  final List<AtividadeDaComunidade> comunidade;

  /// A última proposta que chegou a `lancarAtividade`, para afirmar a origem que o app mandou.
  Proposta? ultimaProposta;

  Object? falhaAoObter;
  Object? falhaAoAtualizar;
  Object? falhaAoListarTurmas;
  Object? falhaAoCriarTurma;
  Object? falhaAoEntrar;
  Object? falhaAoObterTurma;
  Object? falhaAoRegenerar;
  Object? falhaAoSair;
  Object? falhaAoObterAberta;
  Object? falhaAoLancar;
  Object? falhaAoEncerrar;
  Object? falhaAoRegistrar;
  Object? falhaAoApagarRegistro;
  Object? falhaAoListarDiario;
  Object? falhaAoEmbaralhar;
  Object? falhaAoTrocarFoto;
  Object? falhaAoRegistrarDispositivo;
  Object? falhaAoRemoverDispositivo;
  Object? falhaAoListarIdeias;
  Object? falhaAoCriarIdeia;
  Object? falhaAoApagarIdeia;
  Object? falhaAoSalvarDaComunidade;
  Object? falhaAoListarComunidade;

  final chamadas = <String>[];

  /// A plataforma de cada cadastro de aparelho, na ordem; `chamadas` guarda só o token.
  final plataformas = <String>[];

  /// Prendem a chamada até completar: provam o estado de carregando sem depender de timing.
  Completer<void>? segurarObterEu;
  Completer<void>? segurarListarTurmas;
  Completer<void>? segurarObterAberta;
  Completer<void>? segurarListarComunidade;
  Completer<void>? segurarSalvarDaComunidade;

  var _criadas = 0;
  var _regenerados = 0;
  var _lancadas = 0;
  var _registrados = 0;
  var _ideias = 0;

  @override
  Future<Eu> criarEu() async {
    chamadas.add('criarEu');
    return _eu ??= euDeTeste();
  }

  @override
  Future<Eu> obterEu() async {
    chamadas.add('obterEu');
    final segurar = segurarObterEu;
    if (segurar != null) await segurar.future;
    final falha = falhaAoObter;
    if (falha != null) throw falha;
    final eu = _eu;
    if (eu == null) {
      throw const ErroDaApi(
        status: 403,
        codigo: 'perfil_nao_criado',
        mensagem: 'Crie seu perfil antes de continuar.',
      );
    }
    return eu;
  }

  @override
  Future<Eu> atualizarEu(AlteracoesDoEu alteracoes) async {
    chamadas.add('atualizarEu:${jsonEncode(alteracoes.toJson())}');
    final falha = falhaAoAtualizar;
    if (falha != null) throw falha;
    return _eu = _eu!.copyWith(
      nome: alteracoes.nome,
      handle: alteracoes.handle,
      bio: alteracoes.bio,
      atividadesVisiveis: alteracoes.atividadesVisiveis,
    );
  }

  @override
  Future<List<Turma>> listarTurmas() async {
    chamadas.add('listarTurmas');
    final segurar = segurarListarTurmas;
    if (segurar != null) await segurar.future;
    final falha = falhaAoListarTurmas;
    if (falha != null) throw falha;
    return List.of(turmas);
  }

  @override
  Future<Turma> criarTurma({
    required String nome,
    required String emoji,
  }) async {
    chamadas.add('criarTurma:$nome:$emoji');
    final falha = falhaAoCriarTurma;
    if (falha != null) throw falha;
    _criadas++;
    final turma = Turma(
      id: 'nova-$_criadas',
      nome: nome,
      emoji: emoji,
      codigoConvite: 'NOVA${2345 + _criadas}',
      criadorId: _eu!.id,
      vezDe: pessoaDoEu(_eu!),
      totalDeMembros: 1,
      criadoEm: DateTime.utc(2026, 9, 15, 12),
    );
    turmas.add(turma);
    membrosPor[turma.id] = [membroDeTeste(pessoaDoEu(_eu!), 1)];
    return turma;
  }

  @override
  Future<Turma> entrarNaTurma({required String codigo}) async {
    chamadas.add('entrarNaTurma:$codigo');
    final falha = falhaAoEntrar;
    if (falha != null) throw falha;
    final normalizado = codigo.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    for (final minha in turmas) {
      if (minha.codigoConvite == normalizado) return minha; // já era membro
    }
    final convite = convites.remove(normalizado);
    if (convite == null) {
      throw const ErroDaApi(
        status: 422,
        codigo: 'codigo_invalido',
        mensagem: 'Código inválido. Confira com quem te convidou.',
      );
    }
    final turma = convite.copyWith(totalDeMembros: convite.totalDeMembros + 1);
    turmas.add(turma);
    final membros = membrosPor.putIfAbsent(turma.id, () => []);
    membros.add(membroDeTeste(pessoaDoEu(_eu!), membros.length + 1));
    return turma;
  }

  @override
  Future<TurmaDetalhe> obterTurma(String id) async {
    chamadas.add('obterTurma:$id');
    final falha = falhaAoObterTurma;
    if (falha != null) throw falha;
    final turma = _minha(id);
    return TurmaDetalhe(
      turma: turma,
      membros: membrosPor[id] ?? [membroDeTeste(pessoaDoEu(_eu!), 1)],
    );
  }

  @override
  Future<Turma> regenerarConvite(String id) async {
    chamadas.add('regenerarConvite:$id');
    final falha = falhaAoRegenerar;
    if (falha != null) throw falha;
    final turma = _minha(id);
    _regenerados++;
    final nova = turma.copyWith(codigoConvite: 'NOVO${2345 + _regenerados}');
    turmas[turmas.indexOf(turma)] = nova;
    return nova;
  }

  @override
  Future<void> sairDaTurma(String id) async {
    chamadas.add('sairDaTurma:$id');
    final falha = falhaAoSair;
    if (falha != null) throw falha;
    // _minha já lança sem_acesso/não_encontrado; achando, o id está em turmas e o remove não falha.
    turmas.remove(_minha(id));
    membrosPor.remove(id);
  }

  @override
  Future<Atividade?> obterAtividadeAberta(String turmaId) async {
    chamadas.add('obterAtividadeAberta:$turmaId');
    final segurar = segurarObterAberta;
    if (segurar != null) await segurar.future;
    final falha = falhaAoObterAberta;
    if (falha != null) throw falha;
    _minha(turmaId);
    return abertaPor[turmaId];
  }

  @override
  Future<Atividade> lancarAtividade(String turmaId, Proposta proposta) async {
    chamadas.add('lancarAtividade:$turmaId:${proposta.titulo}');
    ultimaProposta = proposta;
    final falha = falhaAoLancar;
    if (falha != null) throw falha;
    final turma = _minha(turmaId);
    if (turma.vezDe.id != _eu!.id) {
      throw const ErroDaApi(
        status: 409,
        codigo: 'nao_e_sua_vez',
        mensagem: 'Ainda não é a sua vez de propor nesta turma.',
      );
    }
    if (abertaPor[turmaId] != null) {
      throw const ErroDaApi(
        status: 409,
        codigo: 'atividade_ja_aberta',
        mensagem:
            'A turma já tem uma atividade aberta. Encerre-a antes de propor outra.',
      );
    }
    final ideiaId = proposta.origemIdeiaId;
    if (ideiaId != null) {
      final livres = ideiasPor[turmaId] ?? <Ideia>[];
      final ideia = livres.where((i) => i.id == ideiaId).firstOrNull;
      if (ideia == null) {
        throw const ErroDaApi(
          status: 409,
          codigo: 'ideia_indisponivel',
          mensagem: 'Essa ideia já foi usada ou apagada.',
        );
      }
      livres.remove(ideia);
    }
    final origemId = proposta.origemAtividadeId;
    if (origemId != null && !comunidade.any((a) => a.id == origemId)) {
      throw const ErroDaApi(
        status: 422,
        codigo: 'dados_invalidos',
        mensagem: 'A atividade de origem não está na Comunidade.',
      );
    }
    _lancadas++;
    final atividade = Atividade(
      id: 'ativ-$_lancadas',
      turmaId: turmaId,
      numero: (diarioPor[turmaId]?.length ?? 0) + 1,
      proponente: pessoaDoEu(_eu!),
      titulo: proposta.titulo,
      descricao: proposta.descricao,
      regras: proposta.regras,
      formato: proposta.formato,
      publica: proposta.publica,
      prazo: proposta.prazo,
      lancadaEm: DateTime.utc(2026, 9, 29, 12),
      encerradaEm: null,
      registros: const [],
    );
    abertaPor[turmaId] = atividade;
    return atividade;
  }

  @override
  Future<Encerramento> encerrarAtividade(String atividadeId) async {
    chamadas.add('encerrarAtividade:$atividadeId');
    final falha = falhaAoEncerrar;
    if (falha != null) throw falha;
    final turmaId = _turmaDaAberta(atividadeId);
    final atividade = abertaPor[turmaId]!;
    if (atividade.proponente.id != _eu!.id) {
      throw const ErroDaApi(
        status: 403,
        codigo: 'sem_acesso',
        mensagem: 'Só quem propôs pode encerrar.',
      );
    }
    final encerrada = atividade.copyWith(
      encerradaEm: DateTime.utc(2026, 9, 30, 10),
    );
    abertaPor[turmaId] = null;
    diarioPor.putIfAbsent(turmaId, () => []).insert(0, encerrada);
    final turma = _minha(turmaId);
    final nova = turma.copyWith(
      vezDe: _proximoDepoisDe(turmaId, turma.vezDe.id),
    );
    turmas[turmas.indexOf(turma)] = nova;
    return Encerramento(atividade: encerrada, turma: nova);
  }

  @override
  Future<Registro> registrar(
    String atividadeId, {
    required FotoParaEnviar foto,
    String legenda = '',
  }) async {
    chamadas.add('registrar:$atividadeId:$legenda');
    final falha = falhaAoRegistrar;
    if (falha != null) throw falha;
    final turmaId = _turmaDaAberta(atividadeId);
    final atividade = abertaPor[turmaId]!;
    final eu = _eu!;
    switch (atividade.formato) {
      case FormatoDeAtividade.grupo:
        if (atividade.proponente.id != eu.id) {
          throw const ErroDaApi(
            status: 409,
            codigo: 'so_o_proponente_registra',
            mensagem: 'Em atividade em grupo, só quem propôs posta as fotos.',
          );
        }
        if (atividade.registros.length >= 10) {
          throw const ErroDaApi(
            status: 409,
            codigo: 'limite_de_fotos',
            mensagem: 'Uma atividade em grupo aceita até 10 fotos.',
          );
        }
      case FormatoDeAtividade.individual:
        if (atividade.registroDe(eu.id) != null) {
          throw const ErroDaApi(
            status: 409,
            codigo: 'ja_registrou',
            mensagem:
                'Você já postou o seu registro. Apague-o para postar outro.',
          );
        }
    }
    _registrados++;
    final registro = Registro(
      id: 'reg-$_registrados',
      autor: pessoaDoEu(eu),
      fotoUrl: 'http://midia.local/midia/registros/reg-$_registrados.jpg',
      miniaturaUrl:
          'http://midia.local/midia/registros/reg-$_registrados.min.jpg',
      legenda: legenda,
      criadoEm: DateTime.utc(2026, 9, 29, 13, _registrados),
    );
    abertaPor[turmaId] = atividade.copyWith(
      registros: [...atividade.registros, registro],
    );
    return registro;
  }

  @override
  Future<void> apagarRegistro(String registroId) async {
    chamadas.add('apagarRegistro:$registroId');
    final falha = falhaAoApagarRegistro;
    if (falha != null) throw falha;
    // acha primeiro, grava depois: não mexer no mapa durante a iteração
    String? turmaId;
    Atividade? atividade;
    Registro? registro;
    for (final entrada in abertaPor.entries) {
      final a = entrada.value;
      final r = a?.registros.where((r) => r.id == registroId).firstOrNull;
      if (a != null && r != null) {
        turmaId = entrada.key;
        atividade = a;
        registro = r;
        break;
      }
    }
    if (atividade != null && registro != null) {
      if (registro.autor.id != _eu!.id) {
        throw const ErroDaApi(
          status: 403,
          codigo: 'sem_acesso',
          mensagem: 'Só quem postou pode apagar.',
        );
      }
      abertaPor[turmaId!] = atividade.copyWith(
        registros: [
          for (final r in atividade.registros)
            if (r.id != registroId) r,
        ],
      );
      return;
    }
    for (final encerradas in diarioPor.values) {
      for (final a in encerradas) {
        if (a.registros.any((r) => r.id == registroId)) {
          throw const ErroDaApi(
            status: 409,
            codigo: 'atividade_encerrada',
            mensagem: 'Esta atividade já foi encerrada.',
          );
        }
      }
    }
    throw const ErroDaApi(
      status: 404,
      codigo: 'nao_encontrado',
      mensagem: 'Não encontramos o que você procura.',
    );
  }

  @override
  Future<PaginaDoDiario> listarDiario(
    String turmaId, {
    String? apos,
    int limite = 20,
  }) async {
    chamadas.add('listarDiario:$turmaId:${apos ?? ''}');
    final falha = falhaAoListarDiario;
    if (falha != null) throw falha;
    _minha(turmaId);
    final todas = diarioPor[turmaId] ?? const <Atividade>[];
    // o cursor do dublê é o índice de onde a página começa
    final inicio = apos == null ? 0 : int.parse(apos);
    final itens = todas.skip(inicio).take(limite).toList();
    final fim = inicio + itens.length;
    return PaginaDoDiario(
      itens: itens,
      proximo: fim < todas.length ? '$fim' : null,
    );
  }

  @override
  Future<TurmaDetalhe> embaralharOrdem(String turmaId) async {
    chamadas.add('embaralharOrdem:$turmaId');
    final falha = falhaAoEmbaralhar;
    if (falha != null) throw falha;
    final turma = _minha(turmaId);
    if (abertaPor[turmaId] != null) {
      throw const ErroDaApi(
        status: 409,
        codigo: 'ordem_travada',
        mensagem: 'A ordem não pode ser embaralhada com uma atividade aberta.',
      );
    }
    // determinístico: inverte as ordens (com dois membros é o que a API garante)
    final membros = membrosPor[turmaId] ?? [membroDeTeste(pessoaDoEu(_eu!), 1)];
    final ordens = [for (final m in membros) m.ordem]..sort();
    final invertidos = [
      for (var i = 0; i < membros.length; i++)
        Membro(
          pessoa: membros[i].pessoa,
          ordem: ordens[membros.length - 1 - i],
          entrouEm: membros[i].entrouEm,
        ),
    ]..sort((a, b) => a.ordem.compareTo(b.ordem));
    membrosPor[turmaId] = invertidos;
    return TurmaDetalhe(turma: turma, membros: invertidos);
  }

  @override
  Future<Eu> trocarFoto(FotoParaEnviar foto) async {
    chamadas.add('trocarFoto:${foto.nome}');
    final falha = falhaAoTrocarFoto;
    if (falha != null) throw falha;
    return _eu = _eu!.copyWith(
      fotoUrl: 'http://midia.local/midia/perfis/${foto.nome}',
    );
  }

  @override
  Future<void> registrarDispositivo({
    required String token,
    required String plataforma,
  }) async {
    chamadas.add('registrarDispositivo:$token');
    plataformas.add(plataforma);
    final falha = falhaAoRegistrarDispositivo;
    if (falha != null) throw falha;
  }

  @override
  Future<void> removerDispositivo(String token) async {
    chamadas.add('removerDispositivo:$token');
    final falha = falhaAoRemoverDispositivo;
    if (falha != null) throw falha;
  }

  @override
  Future<List<Ideia>> listarIdeias(String turmaId) async {
    chamadas.add('listarIdeias:$turmaId');
    final falha = falhaAoListarIdeias;
    if (falha != null) throw falha;
    _minha(turmaId);
    return List.of(ideiasPor[turmaId] ?? const <Ideia>[]);
  }

  @override
  Future<Ideia> criarIdeia(
    String turmaId, {
    required String titulo,
    String descricao = '',
  }) async {
    chamadas.add('criarIdeia:$turmaId:$titulo');
    final falha = falhaAoCriarIdeia;
    if (falha != null) throw falha;
    _minha(turmaId);
    _exigirVagaNoBacklog(turmaId);
    return _guardarIdeia(turmaId, titulo: titulo, descricao: descricao);
  }

  @override
  Future<void> apagarIdeia(String ideiaId) async {
    chamadas.add('apagarIdeia:$ideiaId');
    final falha = falhaAoApagarIdeia;
    if (falha != null) throw falha;
    for (final livres in ideiasPor.values) {
      final ideia = livres.where((i) => i.id == ideiaId).firstOrNull;
      if (ideia == null) continue;
      if (ideia.autor.id != _eu!.id) {
        throw const ErroDaApi(
          status: 403,
          codigo: 'sem_acesso',
          mensagem: 'Só quem sugeriu pode apagar a ideia.',
        );
      }
      livres.remove(ideia);
      return;
    }
    throw const ErroDaApi(
      status: 404,
      codigo: 'nao_encontrado',
      mensagem: 'Não encontramos o que você procura.',
    );
  }

  @override
  Future<Ideia> salvarDaComunidade(
    String atividadeId, {
    required String turmaId,
  }) async {
    chamadas.add('salvarDaComunidade:$atividadeId:$turmaId');
    final segurar = segurarSalvarDaComunidade;
    if (segurar != null) await segurar.future;
    final falha = falhaAoSalvarDaComunidade;
    if (falha != null) throw falha;
    _minha(turmaId);
    final origem = comunidade.where((a) => a.id == atividadeId).firstOrNull;
    if (origem == null) {
      throw const ErroDaApi(
        status: 404,
        codigo: 'nao_encontrado',
        mensagem: 'Não encontramos o que você procura.',
      );
    }
    final livres = ideiasPor[turmaId] ?? const <Ideia>[];
    // a duplicata informa mais do que "cheio": vem antes do teto
    if (livres.any((i) => i.origemAtividadeId == atividadeId)) {
      throw const ErroDaApi(
        status: 409,
        codigo: 'ja_no_backlog',
        mensagem: 'Essa ideia já está no backlog da turma.',
      );
    }
    _exigirVagaNoBacklog(turmaId);
    return _guardarIdeia(
      turmaId,
      titulo: origem.titulo,
      descricao: origem.descricao,
      regras: origem.regras,
      formato: origem.formato,
      origemAtividadeId: origem.id,
    );
  }

  @override
  Future<PaginaDaComunidade> listarComunidade({
    String? apos,
    int limite = 20,
  }) async {
    chamadas.add('listarComunidade:${apos ?? ''}');
    final segurar = segurarListarComunidade;
    if (segurar != null) await segurar.future;
    final falha = falhaAoListarComunidade;
    if (falha != null) throw falha;
    // o cursor do dublê é o índice de onde a página começa
    final inicio = apos == null ? 0 : int.parse(apos);
    final itens = comunidade.skip(inicio).take(limite).toList();
    final fim = inicio + itens.length;
    return PaginaDaComunidade(
      itens: itens,
      proximo: fim < comunidade.length ? '$fim' : null,
    );
  }

  void _exigirVagaNoBacklog(String turmaId) {
    final minhas = (ideiasPor[turmaId] ?? const <Ideia>[])
        .where((i) => i.autor.id == _eu!.id)
        .length;
    if (minhas >= 5) {
      throw const ErroDaApi(
        status: 409,
        codigo: 'backlog_cheio',
        mensagem:
            'Você já tem 5 ideias guardadas nesta turma. Use ou apague uma para guardar outra.',
      );
    }
  }

  Ideia _guardarIdeia(
    String turmaId, {
    required String titulo,
    required String descricao,
    List<String> regras = const [],
    FormatoDeAtividade? formato,
    String? origemAtividadeId,
  }) {
    _ideias++;
    final ideia = Ideia(
      id: 'ideia-nova-$_ideias',
      titulo: titulo,
      descricao: descricao,
      regras: regras,
      formato: formato,
      origemAtividadeId: origemAtividadeId,
      autor: pessoaDoEu(_eu!),
      criadoEm: DateTime.utc(2026, 10, 6, 12, _ideias),
    );
    ideiasPor.putIfAbsent(turmaId, () => []).insert(0, ideia);
    return ideia;
  }

  /// A turma cuja aberta tem este id; 404 se nenhuma, 409 se ela já está no Diário.
  String _turmaDaAberta(String atividadeId) {
    for (final entrada in abertaPor.entries) {
      if (entrada.value?.id == atividadeId) return entrada.key;
    }
    for (final encerradas in diarioPor.values) {
      if (encerradas.any((a) => a.id == atividadeId)) {
        throw const ErroDaApi(
          status: 409,
          codigo: 'atividade_encerrada',
          mensagem: 'Esta atividade já foi encerrada.',
        );
      }
    }
    throw const ErroDaApi(
      status: 404,
      codigo: 'nao_encontrado',
      mensagem: 'Não encontramos o que você procura.',
    );
  }

  /// Quem vem depois na ordem; sem ninguém depois, o primeiro; sem lista de membros, o próprio.
  Pessoa _proximoDepoisDe(String turmaId, String usuarioId) {
    final membros = [...?membrosPor[turmaId]]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    if (membros.isEmpty) return pessoaDoEu(_eu!);
    final indice = membros.indexWhere((m) => m.pessoa.id == usuarioId);
    return membros[(indice + 1) % membros.length].pessoa;
  }

  Turma _minha(String id) {
    for (final turma in turmas) {
      if (turma.id == id) return turma;
    }
    for (final turma in convites.values) {
      if (turma.id == id) {
        throw const ErroDaApi(
          status: 403,
          codigo: 'sem_acesso',
          mensagem: 'Você não faz parte desta turma.',
        );
      }
    }
    throw const ErroDaApi(
      status: 404,
      codigo: 'nao_encontrado',
      mensagem: 'Não encontramos o que você procura.',
    );
  }
}

Eu euDeTeste({
  String nome = 'Marina Duarte',
  String handle = 'marina.d',
  String? fotoUrl,
  String bio = '',
  bool atividadesVisiveis = true,
}) => Eu(
  id: 'usuario-teste',
  handle: handle,
  nome: nome,
  fotoUrl: fotoUrl,
  bio: bio,
  codigoDeAmigo: 'ABCDEFGH',
  atividadesVisiveis: atividadesVisiveis,
  criadoEm: DateTime.utc(2026, 9, 11, 15),
);

Pessoa pessoaDoEu(Eu eu) =>
    Pessoa(id: eu.id, handle: eu.handle, nome: eu.nome, fotoUrl: eu.fotoUrl);

Pessoa pessoaDeTeste({
  String id = 'pessoa-bia',
  String handle = 'bia',
  String nome = 'Bia Souza',
  String? fotoUrl,
}) => Pessoa(id: id, handle: handle, nome: nome, fotoUrl: fotoUrl);

/// Sem `vezDe`, a vez é do eu de teste (id `usuario-teste`).
Turma turmaDeTeste({
  String id = 'turma-1',
  String nome = 'Turma do Domingo',
  String emoji = '🌿',
  String codigoConvite = 'ABCD2345',
  String criadorId = 'usuario-teste',
  Pessoa? vezDe,
  int totalDeMembros = 1,
}) => Turma(
  id: id,
  nome: nome,
  emoji: emoji,
  codigoConvite: codigoConvite,
  criadorId: criadorId,
  vezDe: vezDe ?? pessoaDoEu(euDeTeste()),
  totalDeMembros: totalDeMembros,
  criadoEm: DateTime.utc(2026, 9, 15, 12),
);

Membro membroDeTeste(Pessoa pessoa, int ordem) => Membro(
  pessoa: pessoa,
  ordem: ordem,
  entrouEm: DateTime.utc(2026, 9, 15, 12, ordem),
);

Atividade atividadeDeTeste({
  String id = 'ativ-1',
  String turmaId = 'turma-1',
  int numero = 1,
  Pessoa? proponente,
  String titulo = 'Piquenique Temático de Comidas Amarelas',
  String descricao =
      'Cada membro leva uma receita ou lanche que seja totalmente amarelo.',
  List<String> regras = const ['Pelo menos um item amarelo por pessoa'],
  FormatoDeAtividade formato = FormatoDeAtividade.individual,
  bool publica = true,
  DateTime? prazo,
  DateTime? lancadaEm,
  DateTime? encerradaEm,
  List<Registro> registros = const [],
}) => Atividade(
  id: id,
  turmaId: turmaId,
  numero: numero,
  proponente: proponente ?? pessoaDoEu(euDeTeste()),
  titulo: titulo,
  descricao: descricao,
  regras: regras,
  formato: formato,
  publica: publica,
  prazo: prazo,
  lancadaEm: lancadaEm ?? DateTime.utc(2026, 9, 29, 10),
  encerradaEm: encerradaEm,
  registros: registros,
);

Registro registroDeTeste({
  String id = 'reg-1',
  Pessoa? autor,
  String legenda = 'Bolo de milho',
  DateTime? criadoEm,
}) => Registro(
  id: id,
  autor: autor ?? pessoaDeTeste(),
  fotoUrl: 'http://midia.local/midia/registros/$id.jpg',
  miniaturaUrl: 'http://midia.local/midia/registros/$id.min.jpg',
  legenda: legenda,
  criadoEm: criadoEm ?? DateTime.utc(2026, 9, 29, 11),
);

FotoParaEnviar fotoDeTeste({String nome = 'foto.jpg'}) => FotoParaEnviar(
  bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xE0]),
  nome: nome,
);

/// Sem `autor`, a ideia é minha (a do eu de teste).
Ideia ideiaDeTeste({
  String id = 'ideia-1',
  String titulo = 'Noite de pizza',
  String descricao = '',
  List<String> regras = const [],
  FormatoDeAtividade? formato,
  String? origemAtividadeId,
  Pessoa? autor,
  DateTime? criadoEm,
}) => Ideia(
  id: id,
  titulo: titulo,
  descricao: descricao,
  regras: regras,
  formato: formato,
  origemAtividadeId: origemAtividadeId,
  autor: autor ?? pessoaDoEu(euDeTeste()),
  criadoEm: criadoEm ?? DateTime.utc(2026, 10, 6, 12),
);

FotoDaComunidade fotoDaComunidadeDeTeste({
  String id = 'f1',
  String legenda = 'Vitória da Bia',
}) => FotoDaComunidade(
  fotoUrl: 'http://midia.local/midia/registros/$id.jpg',
  miniaturaUrl: 'http://midia.local/midia/registros/$id.min.jpg',
  legenda: legenda,
);

/// Sem `fotos`, uma foto; sem pessoa nenhuma, como a API.
AtividadeDaComunidade atividadeDaComunidadeDeTeste({
  String id = 'com-1',
  String titulo = 'Noite de jogos',
  String descricao = 'Cada um leva um jogo.',
  List<String> regras = const ['Um jogo por pessoa'],
  FormatoDeAtividade formato = FormatoDeAtividade.grupo,
  DateTime? encerradaEm,
  String turmaNome = 'Turma Prova',
  String turmaEmoji = '🍕',
  List<FotoDaComunidade>? fotos,
  int inspiradas = 0,
}) => AtividadeDaComunidade(
  id: id,
  titulo: titulo,
  descricao: descricao,
  regras: regras,
  formato: formato,
  encerradaEm: encerradaEm ?? DateTime.utc(2026, 10, 4, 21, 30),
  turmaNome: turmaNome,
  turmaEmoji: turmaEmoji,
  fotos: fotos ?? [fotoDaComunidadeDeTeste()],
  inspiradas: inspiradas,
);
