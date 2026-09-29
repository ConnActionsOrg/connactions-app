import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/seletor_de_foto.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';

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
