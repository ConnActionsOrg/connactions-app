import '../../api/modelos/turma.dart';

/// O que vai pelo WhatsApp. Sem link: o esquema connactions:// não é clicável lá, e o domínio
/// ainda não existe.
String textoDoConvite(Turma turma) =>
    'Vem pra turma ${turma.emoji} ${turma.nome} no ConnActions! '
    'Abra o app, toque em Entrar com código e digite ${turma.codigoConvite}.';
