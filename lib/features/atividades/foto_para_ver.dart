import '../../api/modelos/foto_sem_autor.dart';
import '../../api/modelos/pessoa.dart';
import '../../api/modelos/registro.dart';

/// O que o visualizador mostra de uma foto, venha ela de onde vier: o par do `FotoParaEnviar`. O
/// registro de uma atividade traz id, autor e quando foi postado; a foto sem autor (a da Comunidade e
/// a do perfil) só traz a url e a legenda, porque a API não manda pessoa.
class FotoParaVer {
  const FotoParaVer({
    required this.url,
    required this.legenda,
    this.id,
    this.autor,
    this.postadaEm,
  });

  factory FotoParaVer.doRegistro(Registro registro) => FotoParaVer(
    url: registro.fotoUrl,
    legenda: registro.legenda,
    id: registro.id,
    autor: registro.autor,
    postadaEm: registro.criadoEm,
  );

  factory FotoParaVer.semAutor(FotoSemAutor foto) =>
      FotoParaVer(url: foto.fotoUrl, legenda: foto.legenda);

  final String url;
  final String legenda;
  final String? id;
  final Pessoa? autor;
  final DateTime? postadaEm;
}
