import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/eu.dart';
import '../../api/modelos/pessoa.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';
import '../../app/sessao.dart';
import 'perfil_da_pessoa.dart';

/// Minhas conexões, a mais recente primeiro. Espera o perfil, como as turmas: sem conta, vazia.
class Conexoes extends AsyncNotifier<List<Pessoa>>
    with EsperaOBuild<List<Pessoa>> {
  @override
  Future<List<Pessoa>> build() async {
    final Eu? eu;
    try {
      eu = await ref.read(perfilAtualProvider.future);
    } finally {
      // só a troca de conta refaz a lista, não a foto nem o código novo; no finally, para voltar
      // com o perfil que falhou; depois do await, porque o perfil que chega refaria o build
      ref.watch(perfilAtualProvider.select((perfil) => perfil.value?.id));
    }
    if (eu == null) return const [];
    return ref.watch(apiProvider).listarConexoes();
  }

  /// Conecta pelo código de amigo e devolve o record para a tela escolher o aviso. A pessoa entra
  /// na ponta da lista sem duplicar, e os meus contadores são relidos.
  Future<({Pessoa pessoa, bool nova})> conectar(String codigo) async {
    final api = ref.read(apiProvider);
    try {
      await assentado; // um build em voo sobrescreveria o que gravarmos abaixo
    } catch (_) {
      // a lista que não carregou não prende o conectar: ela é relida no fim
    }
    final resultado = await api.conectar(codigo);
    if (!ref.mounted) return resultado;
    final atuais = state.value;
    final pessoa = resultado.pessoa;
    if (atuais == null) {
      ref.invalidateSelf();
    } else if (resultado.nova || !atuais.any((p) => p.id == pessoa.id)) {
      // já éramos conexão e a lista não sabia (ela conectou do aparelho dela): na ponta também
      state = AsyncData([
        pessoa,
        for (final p in atuais)
          if (p.id != pessoa.id) p,
      ]);
    }
    _invalidarMeusContadores();
    return resultado;
  }

  /// Desfaz a conexão: a pessoa sai da lista, e o perfil e as atividades dela e os meus contadores
  /// são relidos.
  Future<void> desconectar(String id) async {
    final api = ref.read(apiProvider);
    await assentado; // um build em voo sobrescreveria o que gravarmos abaixo
    await api.desconectar(id);
    if (!ref.mounted) return;
    state = AsyncData([
      for (final p in state.value ?? const <Pessoa>[])
        if (p.id != id) p,
    ]);
    ref.invalidate(perfilDaPessoaProvider(id));
    ref.invalidate(atividadesFeitasProvider(id));
    _invalidarMeusContadores();
  }

  void _invalidarMeusContadores() {
    final eu = ref.read(perfilAtualProvider).value;
    if (eu != null) ref.invalidate(perfilDaPessoaProvider(eu.id));
  }
}

// Sem autoDispose: o Perfil vive no IndexedStack. Sem retry: a tela oferece "Tentar de novo".
final conexoesProvider = AsyncNotifierProvider<Conexoes, List<Pessoa>>(
  Conexoes.new,
  retry: (_, _) => null,
);

/// A lista que a tela pode mostrar. Recarregando por dependência (a conta trocou, que é a única que
/// o build observa), o valor que sobrou é o da conta anterior e fica de fora.
List<Pessoa>? amigosDaConta(AsyncValue<List<Pessoa>> conexoes) =>
    conexoes.isReloading ? null : conexoes.value;
