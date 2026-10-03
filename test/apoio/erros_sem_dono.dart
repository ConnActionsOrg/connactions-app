import 'dart:async';

/// Roda [corpo] e devolve os erros que escaparam de um `Future` sem dono (um `onPressed` ou um
/// `Stream.listen` que o descarta). O flutter_test aborta o teste no primeiro deles, por fora de
/// qualquer asserção, e `takeException()` já volta nulo depois disso: só a lista permite afirmar.
Future<List<Object>> errosSemDono(Future<void> Function() corpo) {
  final soltos = <Object>[];
  final fim = Completer<void>();
  runZonedGuarded(() async {
    try {
      await corpo();
      fim.complete();
    } catch (erro, pilha) {
      // o Dart não leva o erro de um Future para fora de uma zona de erro: sem este Completer a
      // falha do próprio corpo (um expect, por exemplo) cairia na lista e o teste ficaria pendurado
      fim.completeError(erro, pilha);
    }
  }, (erro, _) => soltos.add(erro));
  return fim.future.then((_) => soltos);
}
