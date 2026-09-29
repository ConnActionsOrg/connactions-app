import 'package:image_picker/image_picker.dart';

import '../api/modelos/foto_para_enviar.dart';

enum OrigemDaFoto { camera, galeria }

/// Fronteira com a câmera e a galeria do aparelho. As telas só conhecem esta interface.
abstract class SeletorDeFoto {
  /// `null` quando a pessoa cancela.
  Future<FotoParaEnviar?> escolher(OrigemDaFoto origem);
}

/// Encolhe no aparelho (1600px, qualidade 85): o upload fica pequeno no 4G e a API só normaliza.
class SeletorDeFotoDoAparelho implements SeletorDeFoto {
  SeletorDeFotoDoAparelho({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<FotoParaEnviar?> escolher(OrigemDaFoto origem) async {
    final arquivo = await _picker.pickImage(
      source: switch (origem) {
        OrigemDaFoto.camera => ImageSource.camera,
        OrigemDaFoto.galeria => ImageSource.gallery,
      },
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (arquivo == null) return null;
    return FotoParaEnviar(
      bytes: await arquivo.readAsBytes(),
      nome: arquivo.name,
    );
  }
}
