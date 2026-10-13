import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/pagina_da_comunidade.dart';
import '../../api/modelos/turma.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';
import '../turmas/turmas.dart';

/// Os ids das minhas turmas, ordenados e juntos numa String. Entrar ou sair de uma turma muda o que
/// é "outra turma"; a vez que andou ou um convite novo, não. Um `Set` ou `List` novo nunca é `==` ao
/// anterior e releria a Comunidade a cada recarga da lista.
String _idsDasTurmas(AsyncValue<List<Turma>> turmas) =>
    ([for (final t in turmas.value ?? const <Turma>[]) t.id]..sort()).join(',');

/// As atividades públicas de outras turmas, acumuladas página a página.
class Comunidade extends AsyncNotifier<PaginaDaComunidade>
    with EsperaOBuild<PaginaDaComunidade> {
  @override
  Future<PaginaDaComunidade> build() async {
    // o perfil e as turmas primeiro: a API exige o perfil criado antes de qualquer rota
    await ref.read(turmasProvider.future);
    ref.watch(turmasProvider.select(_idsDasTurmas));
    return ref.watch(apiProvider).listarComunidade();
  }

  /// Pede a página seguinte e concatena; sem `proximo`, não faz nada.
  Future<void> carregarMais() async {
    final api = ref.read(apiProvider);
    final atual = await assentado;
    final proximo = atual.proximo;
    if (proximo == null) return;
    final pagina = await api.listarComunidade(apos: proximo);
    if (!ref.mounted) return;
    state = AsyncData(
      PaginaDaComunidade(
        itens: [...atual.itens, ...pagina.itens],
        proximo: pagina.proximo,
      ),
    );
  }
}

// Sem retry automático: a tela oferece "Tentar de novo".
final comunidadeProvider =
    AsyncNotifierProvider.autoDispose<Comunidade, PaginaDaComunidade>(
      Comunidade.new,
      retry: (_, _) => null,
    );
