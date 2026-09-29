import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/app/seletor_de_foto.dart';

/// Devolve a foto configurada (ou `null`, como quem cancelou) e anota a origem pedida.
class SeletorDeFotoFalso implements SeletorDeFoto {
  SeletorDeFotoFalso({this.foto});

  FotoParaEnviar? foto;
  final origens = <OrigemDaFoto>[];

  @override
  Future<FotoParaEnviar?> escolher(OrigemDaFoto origem) async {
    origens.add(origem);
    return foto;
  }
}
