import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/medidas.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_vazio.dart';
import '../turmas/seletor_de_turma.dart';
import '../turmas/turmas.dart';

/// O Diário é por turma: a mesma pílula do Feed escolhe qual. O conteúdo chega na fatia 5.
class TelaDoDiario extends ConsumerWidget {
  const TelaDoDiario({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turma = ref.watch(turmaAtivaProvider);
    return Scaffold(
      appBar: const Cabecalho(),
      body: turma == null
          ? const EstadoVazio(
              icone: Symbols.auto_stories,
              titulo: 'O diário começa vazio',
              texto: 'Cada atividade encerrada vira uma memória da turma aqui.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Espacos.margemDaTela,
                Espacos.md,
                Espacos.margemDaTela,
                Espacos.xl,
              ),
              children: [
                const SeletorDeTurma(),
                const SizedBox(height: Espacos.xl),
                EstadoVazio(
                  icone: Symbols.auto_stories,
                  titulo: 'O diário da turma começa vazio',
                  texto:
                      'As atividades encerradas de ${turma.emoji} ${turma.nome} vão aparecer aqui.',
                ),
              ],
            ),
    );
  }
}
