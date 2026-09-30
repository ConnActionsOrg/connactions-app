import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/erro_da_api.dart';
import '../api/modelos/alteracoes_do_eu.dart';
import '../api/modelos/eu.dart';
import '../api/modelos/foto_para_enviar.dart';
import 'assentado.dart';
import 'autenticador.dart';
import 'dependencias.dart';

/// Conta logada no Firebase; `null` enquanto deslogado.
final contaProvider = StreamProvider<ContaLogada?>(
  (ref) => ref.watch(autenticadorProvider).mudancas,
);

/// Perfil da pessoa logada, vindo da API. A primeira entrada é o cadastro: sem perfil (403), cria.
class PerfilAtual extends AsyncNotifier<Eu?> with EsperaOBuild<Eu?> {
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

  /// Não otimista: a API valida o handle e pode recusar. Devolve o Eu gravado.
  Future<Eu> atualizar(AlteracoesDoEu alteracoes) async {
    final salvo = await ref.read(apiProvider).atualizarEu(alteracoes);
    if (ref.mounted) state = AsyncData(salvo);
    return salvo;
  }

  /// Não otimista: o Eu volta com a URL da foto nova.
  Future<Eu> trocarFoto(FotoParaEnviar foto) async {
    await assentado; // um build em voo sobrescreveria o que gravarmos abaixo
    final salvo = await ref.read(apiProvider).trocarFoto(foto);
    if (ref.mounted) state = AsyncData(salvo);
    return salvo;
  }

  /// Otimista: a tela muda na hora e volta se a API recusar; o erro sobe para quem chamou avisar.
  Future<void> definirVisibilidade(bool visiveis) async {
    final atual = state.value;
    if (atual == null) return;
    state = AsyncData(atual.copyWith(atividadesVisiveis: visiveis));
    try {
      final salvo = await ref
          .read(apiProvider)
          .atualizarEu(AlteracoesDoEu(atividadesVisiveis: visiveis));
      // quem deslogou no meio do PATCH não pode receber o perfil velho de volta
      if (ref.mounted) state = AsyncData(salvo);
    } catch (_) {
      if (ref.mounted) state = AsyncData(atual);
      rethrow;
    }
  }
}

// Sem retry automático: a tela oferece "Tentar de novo" em vez de martelar a API sozinha.
final perfilAtualProvider = AsyncNotifierProvider<PerfilAtual, Eu?>(
  PerfilAtual.new,
  retry: (_, _) => null,
);
