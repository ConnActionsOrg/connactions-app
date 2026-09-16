import 'package:connactions_app/app/compartilhador.dart';

/// Guarda o que o app pediu para compartilhar, na ordem.
class CompartilhadorFalso implements Compartilhador {
  final textos = <String>[];

  @override
  Future<void> compartilhar(String texto) async => textos.add(texto);
}
