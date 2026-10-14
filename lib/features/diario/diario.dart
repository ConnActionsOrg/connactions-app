import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/pagina_do_diario.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';

/// As encerradas de uma turma, acumuladas página a página.
class Diario extends AsyncNotifier<PaginaDoDiario>
    with EsperaOBuild<PaginaDoDiario> {
  Diario(this.turmaId);

  final String turmaId;

  @override
  Future<PaginaDoDiario> build() =>
      ref.watch(apiProvider).listarDiario(turmaId);

  /// Pede a página seguinte e concatena; sem `proximo`, não faz nada.
  Future<void> carregarMais() async {
    final atual = await assentado;
    final proximo = atual.proximo;
    if (proximo == null) return;
    final pagina = await ref
        .read(apiProvider)
        .listarDiario(turmaId, apos: proximo);
    if (!ref.mounted) return;
    state = AsyncData(
      PaginaDoDiario(
        itens: [...atual.itens, ...pagina.itens],
        proximo: pagina.proximo,
        capa: atual.capa, // só a 1ª página traz a capa
      ),
    );
  }
}

final diarioProvider = AsyncNotifierProvider.autoDispose
    .family<Diario, PaginaDoDiario, String>(Diario.new, retry: (_, _) => null);
