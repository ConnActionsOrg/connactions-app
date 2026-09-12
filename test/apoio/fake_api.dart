import 'dart:async';

import 'package:connactions_app/api/api_connactions.dart';
import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/eu.dart';

/// Dublê da API em memória. Registra as chamadas para os testes afirmarem o que o app pediu.
class FakeApi implements ApiConnactions {
  FakeApi({this._eu, this.falhaAoObter, this.falhaAoAtualizar});

  Eu? _eu;
  Object? falhaAoObter;
  Object? falhaAoAtualizar;
  final chamadas = <String>[];

  /// Prende `obterEu` até completar: prova o estado de carregando sem depender de timing.
  Completer<void>? segurarObterEu;

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
  Future<Eu> atualizarVisibilidade({required bool visiveis}) async {
    chamadas.add('atualizarVisibilidade:$visiveis');
    final falha = falhaAoAtualizar;
    if (falha != null) throw falha;
    return _eu = _eu!.copyWith(atividadesVisiveis: visiveis);
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
