import 'dart:async';

/// Roda [corpo] e devolve os erros que escaparam de um `Future` sem dono (um `onPressed` ou um
/// `Stream.listen` que o descarta). O flutter_test aborta o teste no primeiro deles, por fora de
/// qualquer asserção, e `takeException()` já volta nulo depois disso: só a lista permite afirmar.
Future<List<Object>> errosSemDono(Future<void> Function() corpo) async {
  final soltos = <Object>[];
  await runZonedGuarded(corpo, (erro, _) => soltos.add(erro));
  return soltos;
}
