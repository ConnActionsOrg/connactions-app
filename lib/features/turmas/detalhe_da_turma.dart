import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/turma.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';

/// Os membros de uma turma, por id. Descartada quando ninguém mais a observa.
class DetalheDaTurma extends AsyncNotifier<TurmaDetalhe>
    with EsperaOBuild<TurmaDetalhe> {
  DetalheDaTurma(this.id);

  final String id;

  @override
  Future<TurmaDetalhe> build() => ref.watch(apiProvider).obterTurma(id);

  /// Grava o detalhe devolvido (os membros já na ordem nova).
  Future<void> embaralhar() async {
    await assentado; // um build em voo sobrescreveria o que gravarmos abaixo
    final detalhe = await ref.read(apiProvider).embaralharOrdem(id);
    if (ref.mounted) state = AsyncData(detalhe);
  }
}

final turmaDetalheProvider = AsyncNotifierProvider.autoDispose
    .family<DetalheDaTurma, TurmaDetalhe, String>(
      DetalheDaTurma.new,
      retry: (_, _) => null,
    );
