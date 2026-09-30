import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/pagina_do_diario.dart';
import '../../app/dependencias.dart';

/// As encerradas de uma turma, acumuladas página a página.
class Diario extends AsyncNotifier<PaginaDoDiario> {
  Diario(this.turmaId);

  final String turmaId;

  @override
  Future<PaginaDoDiario> build() =>
      ref.watch(apiProvider).listarDiario(turmaId);

  /// Pede a página seguinte e concatena; sem `proximo`, não faz nada.
  Future<void> carregarMais() async {
    // Recarga que falhou deixa o erro junto da página que já estava: `await future` repetiria o erro
    // e o botão nunca mais pediria nada. Com uma recarga em voo, espera por ela.
    final atual = state.hasError && state.hasValue && !state.isLoading
        ? state.requireValue
        : await future;
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
      ),
    );
  }
}

final diarioProvider = AsyncNotifierProvider.autoDispose
    .family<Diario, PaginaDoDiario, String>(Diario.new, retry: (_, _) => null);
