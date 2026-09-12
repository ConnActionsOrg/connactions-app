import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/sessao.dart';
import '../../design/medidas.dart';
import '../../design/widgets/cabecalho.dart';

class TelaDoPerfil extends ConsumerWidget {
  const TelaDoPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: const Cabecalho(),
    body: Padding(
      padding: const EdgeInsets.all(Espacos.margemDaTela),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.read(autenticadorProvider).sair(),
          icon: const Icon(Symbols.logout),
          label: const Text('Sair da conta'),
        ),
      ),
    ),
  );
}
