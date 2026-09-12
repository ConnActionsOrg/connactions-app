import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_vazio.dart';

class TelaDaComunidade extends StatelessWidget {
  const TelaDaComunidade({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: Cabecalho(),
    body: EstadoVazio(
      icone: Symbols.groups_2,
      titulo: 'A comunidade ainda está quieta',
      texto:
          'Atividades públicas das outras turmas vão aparecer aqui para inspirar a sua.',
    ),
  );
}
