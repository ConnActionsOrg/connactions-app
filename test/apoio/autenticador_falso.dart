import 'dart:async';

import 'package:connactions_app/app/autenticador.dart';

const contaDeTeste = ContaLogada(
  uid: 'uid-teste',
  nome: 'Marina Duarte',
  email: 'marina@exemplo.com',
);

/// Dublê do login. Começa com a conta dada (ou deslogado) e troca sob comando dos testes.
class AutenticadorFalso implements Autenticador {
  // "this._conta" tornaria o parâmetro nomeado privado (_conta), quebrando
  // AutenticadorFalso(conta: ...) fora desta biblioteca.
  AutenticadorFalso({ContaLogada? conta})
    : _conta = conta; // ignore: prefer_initializing_formals

  ContaLogada? _conta;
  final _trocas = StreamController<ContaLogada?>.broadcast();
  final chamadas = <String>[];
  Object? falhaAoEntrar;

  @override
  Stream<ContaLogada?> get mudancas async* {
    yield _conta;
    yield* _trocas.stream;
  }

  @override
  Future<String?> obterIdToken() async {
    final conta = _conta;
    return conta == null ? null : 'token-${conta.uid}';
  }

  @override
  Future<void> entrarComGoogle() async {
    chamadas.add('entrar');
    final falha = falhaAoEntrar;
    if (falha != null) throw falha;
    _conta = contaDeTeste;
    _trocas.add(_conta);
  }

  @override
  Future<void> sair() async {
    chamadas.add('sair');
    _conta = null;
    _trocas.add(null);
  }
}
