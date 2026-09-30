import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/app/seletor_de_foto.dart';
import 'package:flutter/services.dart';

/// Sem câmera ou com a permissão negada o plugin lança em vez de devolver null.
class SeletorQueLanca implements SeletorDeFoto {
  @override
  Future<FotoParaEnviar?> escolher(OrigemDaFoto origem) =>
      Future.error(PlatformException(code: 'camera_access_denied'));
}
