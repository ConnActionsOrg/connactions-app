import 'package:share_plus/share_plus.dart';

/// Fronteira com a folha de compartilhamento do sistema. As telas só conhecem esta interface.
abstract class Compartilhador {
  Future<void> compartilhar(String texto);
}

class CompartilhadorDoSistema implements Compartilhador {
  const CompartilhadorDoSistema();

  @override
  Future<void> compartilhar(String texto) async {
    await SharePlus.instance.share(ShareParams(text: texto));
  }
}
