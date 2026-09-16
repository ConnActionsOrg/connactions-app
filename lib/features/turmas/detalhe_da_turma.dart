import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/turma.dart';
import '../../app/dependencias.dart';

/// Os membros de uma turma, por id. Descartada quando ninguém mais a observa.
class DetalheDaTurma extends AsyncNotifier<TurmaDetalhe> {
  DetalheDaTurma(this.id);

  final String id;

  @override
  Future<TurmaDetalhe> build() => ref.watch(apiProvider).obterTurma(id);
}

final turmaDetalheProvider = AsyncNotifierProvider.autoDispose
    .family<DetalheDaTurma, TurmaDetalhe, String>(
      DetalheDaTurma.new,
      retry: (_, _) => null,
    );
