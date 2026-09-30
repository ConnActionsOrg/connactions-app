import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/foto_para_enviar.dart';
import '../../app/dependencias.dart';
import '../../app/seletor_de_foto.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';

/// A folha de origem e, escolhida a origem, o seletor do aparelho. `null` quando a pessoa cancela e
/// também quando o aparelho não consegue (sem câmera, permissão negada): o plugin lança em vez de
/// devolver null, e aí o motivo vira aviso.
Future<FotoParaEnviar?> escolherFoto(
  BuildContext context,
  WidgetRef ref,
) async {
  final origem = await mostrarFolhaDeOrigemDaFoto(context);
  if (origem == null || !context.mounted) return null;
  try {
    return await ref.read(seletorDeFotoProvider).escolher(origem);
  } catch (e) {
    if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
    return null;
  }
}

/// "Tirar foto" ou "Escolher da galeria"; fechar sem escolher devolve null.
Future<OrigemDaFoto?> mostrarFolhaDeOrigemDaFoto(BuildContext context) =>
    showModalBottomSheet<OrigemDaFoto>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (contexto) {
        final tipografia = Tipografia.de(contexto);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Espacos.margemDaTela,
            0,
            Espacos.margemDaTela,
            Espacos.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('De onde vem a foto?', style: tipografia.tituloMedio),
              const SizedBox(height: Espacos.sm),
              ListTile(
                leading: const Icon(Symbols.photo_camera),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.pop(contexto, OrigemDaFoto.camera),
              ),
              ListTile(
                leading: const Icon(Symbols.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(contexto, OrigemDaFoto.galeria),
              ),
            ],
          ),
        );
      },
    );
