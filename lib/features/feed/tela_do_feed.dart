import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_vazio.dart';

/// Nesta fatia o Feed só tem o estado vazio; a atividade da vez e as turmas chegam nas fatias 1 e 2.
class TelaDoFeed extends StatelessWidget {
  const TelaDoFeed({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: Cabecalho(),
    body: EstadoVazio(
      icone: Symbols.local_cafe,
      titulo: 'Nenhuma turma por aqui ainda',
      texto:
          'Quando você criar ou entrar numa turma, a atividade da vez aparece aqui.',
    ),
  );
}
