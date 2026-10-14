import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/comentario.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';
import 'diario.dart';

/// A atividade cujos comentários a folha mostra; a turma vai junto para o total do cartão do Diário.
typedef AtividadeDoDiario = ({String turmaId, String atividadeId});

/// Os comentários de uma atividade, acumulados página a página. Postar e apagar também acertam o
/// total do cartão no [Diario].
class Comentarios extends AsyncNotifier<PaginaDeComentarios>
    with EsperaOBuild<PaginaDeComentarios> {
  Comentarios(this.alvo);

  final AtividadeDoDiario alvo;

  @override
  Future<PaginaDeComentarios> build() =>
      ref.watch(apiProvider).listarComentarios(alvo.atividadeId);

  /// Pede a página seguinte e concatena; sem `proximo`, não faz nada.
  Future<void> carregarMais() async {
    final atual = await assentado;
    final proximo = atual.proximo;
    if (proximo == null) return;
    final pagina = await ref
        .read(apiProvider)
        .listarComentarios(alvo.atividadeId, apos: proximo);
    if (!ref.mounted) return;
    state = AsyncData(
      PaginaDeComentarios(
        itens: [...atual.itens, ...pagina.itens],
        proximo: pagina.proximo,
      ),
    );
  }

  /// Grava o comentário. Se a lista já chegou ao fim, ele entra no fim dela; com páginas por carregar
  /// o novo é o último de todos e aparece quando a lista chegar até ele.
  Future<void> comentar(String texto) async {
    final atual = await assentado;
    final novo = await ref.read(apiProvider).comentar(alvo.atividadeId, texto);
    if (!ref.mounted) return;
    final base = state.value ?? atual;
    if (base.proximo == null) {
      state = AsyncData(
        PaginaDeComentarios(itens: [...base.itens, novo], proximo: null),
      );
    }
    ref
        .read(diarioProvider(alvo.turmaId).notifier)
        .ajustarComentarios(alvo.atividadeId, 1);
  }

  Future<void> apagar(String comentarioId) async {
    final atual = await assentado;
    await ref.read(apiProvider).apagarComentario(comentarioId);
    if (!ref.mounted) return;
    final base = state.value ?? atual;
    state = AsyncData(
      PaginaDeComentarios(
        itens: [
          for (final c in base.itens)
            if (c.id != comentarioId) c,
        ],
        proximo: base.proximo,
      ),
    );
    ref
        .read(diarioProvider(alvo.turmaId).notifier)
        .ajustarComentarios(alvo.atividadeId, -1);
  }
}

final comentariosProvider = AsyncNotifierProvider.autoDispose
    .family<Comentarios, PaginaDeComentarios, AtividadeDoDiario>(
      Comentarios.new,
      retry: (_, _) => null,
    );
