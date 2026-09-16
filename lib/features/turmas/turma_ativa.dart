import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/turma.dart';
import '../../app/dependencias.dart';
import '../../app/preferencias.dart';

/// A turma com o id salvo; sem ela (saí, ou o id é de outra conta), a primeira; sem turmas, nada.
Turma? turmaAtiva(List<Turma>? turmas, String? idSalvo) {
  if (turmas == null || turmas.isEmpty) return null;
  for (final turma in turmas) {
    if (turma.id == idSalvo) return turma;
  }
  return turmas.first;
}

/// O id da turma escolhida, guardado no aparelho. Só muda quando a pessoa escolhe outra.
class TurmaAtivaId extends Notifier<String?> {
  @override
  String? build() =>
      ref.watch(preferenciasProvider).ler(ChaveDePreferencia.turmaAtivaId);

  Future<void> definir(String id) async {
    state = id;
    await ref
        .read(preferenciasProvider)
        .gravar(ChaveDePreferencia.turmaAtivaId, id);
  }
}

final turmaAtivaIdProvider = NotifierProvider<TurmaAtivaId, String?>(
  TurmaAtivaId.new,
);
