import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_connactions.dart';
import '../api/erro_da_api.dart';
import '../api/modelos/eu.dart';
import 'autenticador.dart';

/// Pontos de entrada externos. Sem padrão de propósito: o main e os testes têm de sobrescrever.
final autenticadorProvider = Provider<Autenticador>(
  (_) => throw UnimplementedError(
    'sobrescreva autenticadorProvider no ProviderScope',
  ),
);
final apiProvider = Provider<ApiConnactions>(
  (_) => throw UnimplementedError('sobrescreva apiProvider no ProviderScope'),
);

/// Conta logada no Firebase; `null` enquanto deslogado.
final contaProvider = StreamProvider<ContaLogada?>(
  (ref) => ref.watch(autenticadorProvider).mudancas,
);

/// Perfil da pessoa logada, vindo da API. A primeira entrada é o cadastro: sem perfil (403), cria.
class PerfilAtual extends AsyncNotifier<Eu?> {
  @override
  Future<Eu?> build() async {
    final conta = await ref.watch(contaProvider.future);
    if (conta == null) return null;
    final api = ref.watch(apiProvider);
    try {
      return await api.obterEu();
    } on ErroDaApi catch (e) {
      if (e.perfilNaoCriado) return api.criarEu();
      rethrow;
    }
  }

  /// Otimista: a tela muda na hora e volta se a API recusar; o erro sobe para quem chamou avisar.
  Future<void> definirVisibilidade(bool visiveis) async {
    final atual = state.value;
    if (atual == null) return;
    state = AsyncData(atual.copyWith(atividadesVisiveis: visiveis));
    try {
      state = AsyncData(
        await ref.read(apiProvider).atualizarVisibilidade(visiveis: visiveis),
      );
    } catch (_) {
      state = AsyncData(atual);
      rethrow;
    }
  }
}

final perfilAtualProvider = AsyncNotifierProvider<PerfilAtual, Eu?>(
  PerfilAtual.new,
);
