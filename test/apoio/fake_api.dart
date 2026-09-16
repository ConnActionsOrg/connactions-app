import 'dart:async';
import 'dart:convert';

import 'package:connactions_app/api/api_connactions.dart';
import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/alteracoes_do_eu.dart';
import 'package:connactions_app/api/modelos/eu.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/api/modelos/turma.dart';

/// Dublê da API em memória. Registra as chamadas para os testes afirmarem o que o app pediu.
class FakeApi implements ApiConnactions {
  FakeApi({
    Eu? eu,
    List<Turma> turmas = const [],
    Map<String, List<Membro>> membrosPor = const {},
    Map<String, Turma> convites = const {},
    this.falhaAoObter,
    this.falhaAoAtualizar,
    this.falhaAoListarTurmas,
    this.falhaAoCriarTurma,
    this.falhaAoEntrar,
    this.falhaAoObterTurma,
    this.falhaAoRegenerar,
    this.falhaAoSair,
  }) : _eu = eu, // ignore: prefer_initializing_formals
       turmas = List.of(turmas),
       membrosPor = {
         for (final e in membrosPor.entries) e.key: List.of(e.value),
       },
       convites = Map.of(convites);

  Eu? _eu;

  /// Minhas turmas (o que GET /turmas devolve). Criar, entrar e sair mexem aqui.
  final List<Turma> turmas;

  /// Membros por id de turma. Sem entrada, a turma tem só a mim.
  final Map<String, List<Membro>> membrosPor;

  /// Turmas de outras pessoas que aceitam o meu "entrar", pelo código.
  final Map<String, Turma> convites;

  Object? falhaAoObter;
  Object? falhaAoAtualizar;
  Object? falhaAoListarTurmas;
  Object? falhaAoCriarTurma;
  Object? falhaAoEntrar;
  Object? falhaAoObterTurma;
  Object? falhaAoRegenerar;
  Object? falhaAoSair;

  final chamadas = <String>[];

  /// Prendem a chamada até completar: provam o estado de carregando sem depender de timing.
  Completer<void>? segurarObterEu;
  Completer<void>? segurarListarTurmas;

  var _criadas = 0;
  var _regenerados = 0;

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
