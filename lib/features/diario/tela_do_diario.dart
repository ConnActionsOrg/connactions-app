import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_vazio.dart';

class TelaDoDiario extends StatelessWidget {
  const TelaDoDiario({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: Cabecalho(),
    body: EstadoVazio(
      icone: Symbols.auto_stories,
      titulo: 'O diário começa vazio',
      texto: 'Cada atividade encerrada vira uma memória da turma aqui.',
    ),
  );
}
