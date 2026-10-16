import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/atividade_feita.dart';
import '../../api/modelos/perfil_de_pessoa.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';

/// O cabeçalho e os contadores de alguém: de uma conexão, ou o meu, que o Perfil lê só pelos
/// contadores (a minha identidade vem do /eu).
final perfilDaPessoaProvider = FutureProvider.autoDispose
    .family<PerfilDePessoa, String>(
      (ref, id) => ref.watch(apiProvider).obterPerfil(id),
      retry: (_, _) => null,
    );

/// As atividades feitas de alguém, acumuladas página a página.
class AtividadesFeitas extends AsyncNotifier<PaginaDeAtividadesFeitas>
    with EsperaOBuild<PaginaDeAtividadesFeitas> {
  AtividadesFeitas(this.usuarioId);

  final String usuarioId;

  @override
  Future<PaginaDeAtividadesFeitas> build() =>
      ref.watch(apiProvider).listarAtividadesFeitas(usuarioId);

  /// Pede a página seguinte e concatena; sem `proximo`, não faz nada. Se a página falha (a pessoa
  /// desligou a visibilidade no meio), o que já estava fica e o erro sobe para o aviso.
  Future<void> carregarMais() async {
    final api = ref.read(apiProvider);
    final atual = await assentado;
    final proximo = atual.proximo;
    if (proximo == null) return;
    final pagina = await api.listarAtividadesFeitas(usuarioId, apos: proximo);
    if (!ref.mounted) return;
    state = AsyncData(
      PaginaDeAtividadesFeitas(
        itens: [...atual.itens, ...pagina.itens],
        proximo: pagina.proximo,
      ),
    );
  }
}

// Sem retry automático: a tela oferece "Tentar de novo".
final atividadesFeitasProvider = AsyncNotifierProvider.autoDispose
    .family<AtividadesFeitas, PaginaDeAtividadesFeitas, String>(
      AtividadesFeitas.new,
      retry: (_, _) => null,
    );
