import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/capa_do_diario.dart';
import '../../api/modelos/pagina_do_diario.dart';
import '../../api/modelos/reacao.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';

/// As encerradas de uma turma, acumuladas página a página, com as reações e a capa.
class Diario extends AsyncNotifier<PaginaDoDiario>
    with EsperaOBuild<PaginaDoDiario> {
  Diario(this.turmaId);

  final String turmaId;

  // (atividade, tipo) com a chamada em voo: um segundo toque no mesmo chip é ignorado.
  final _reagindo = <String>{};

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

  /// Marca ou desmarca a reação: o cartão muda na hora, e a resposta da API (o resumo inteiro da
  /// atividade) assenta o que ficou valendo. Se a chamada falha, volta o que era e o erro sobe para a
  /// tela avisar.
  Future<void> alternarReacao(String atividadeId, TipoDeReacao tipo) async {
    final chave = '$atividadeId:${tipo.slug}';
    if (!_reagindo.add(chave)) return;
    try {
      await assentado; // um build em voo sobrescreveria o que gravarmos abaixo
      // o item de agora, não o de antes da espera: outro toque pode ter mexido nele nesse meio-tempo
      final item = _item(atividadeId);
      if (item == null) return;
      final antes = item.reacoes.where((r) => r.tipo == tipo).firstOrNull;
      final api = ref.read(apiProvider);

      _trocarReacoes(atividadeId, _alternada(item.reacoes, tipo));
      try {
        final resumo = (antes?.minha ?? false)
            ? await api.desreagir(atividadeId, tipo)
            : await api.reagir(atividadeId, tipo);
        _trocarReacoes(atividadeId, resumo);
      } catch (_) {
        // só o tipo que falhou volta: outro chip da mesma atividade pode estar em voo
        _desfazer(atividadeId, tipo, antes);
        rethrow;
      }
    } finally {
      _reagindo.remove(chave);
    }
  }

  /// A folha de comentários soma 1 ao postar e subtrai 1 ao apagar; o total do cartão é o dela.
  void ajustarComentarios(String atividadeId, int delta) {
    final item = _item(atividadeId);
    if (item == null) return;
    final total = (item.totalDeComentarios + delta).clamp(0, 1 << 30);
    _guardar(item.copyWith(totalDeComentarios: total));
  }

  /// A resposta do PATCH da capa troca a capa da primeira página; os itens ficam como estão.
  void trocarCapa(CapaDoDiario capa) {
    final atual = state.value;
    if (!ref.mounted || atual == null) return;
    state = AsyncData(atual.comCapa(capa));
  }

  ItemDoDiario? _item(String atividadeId) => state.value?.itens
      .where((i) => i.atividade.id == atividadeId)
      .firstOrNull;

  void _guardar(ItemDoDiario item) {
    final atual = state.value;
    if (!ref.mounted || atual == null) return;
    state = AsyncData(atual.comItem(item));
  }

  void _trocarReacoes(String atividadeId, List<Reacao> reacoes) {
    final item = _item(atividadeId);
    if (item != null) _guardar(item.copyWith(reacoes: reacoes));
  }

  void _desfazer(String atividadeId, TipoDeReacao tipo, Reacao? antes) {
    final item = _item(atividadeId);
    if (item == null) return;
    final lista = [
      for (final r in item.reacoes)
        if (r.tipo != tipo) r,
      ?antes,
    ]..sort((a, b) => a.tipo.index.compareTo(b.tipo.index));
    _guardar(item.copyWith(reacoes: lista));
  }
}

/// O resumo depois do toque: marcar soma 1 e põe a minha; desmarcar tira 1 (e o tipo some do resumo
/// quando ninguém mais reagiu). Na ordem fixa dos tipos, como a API devolve.
List<Reacao> _alternada(List<Reacao> resumo, TipoDeReacao tipo) {
  final lista = [...resumo];
  final i = lista.indexWhere((r) => r.tipo == tipo);
  if (i < 0) {
    lista.add(Reacao(tipo: tipo, total: 1, minha: true));
  } else if (lista[i].minha) {
    if (lista[i].total <= 1) {
      lista.removeAt(i);
    } else {
      lista[i] = Reacao(tipo: tipo, total: lista[i].total - 1, minha: false);
    }
  } else {
    lista[i] = Reacao(tipo: tipo, total: lista[i].total + 1, minha: true);
  }
  return lista..sort((a, b) => a.tipo.index.compareTo(b.tipo.index));
}

final diarioProvider = AsyncNotifierProvider.autoDispose
    .family<Diario, PaginaDoDiario, String>(Diario.new, retry: (_, _) => null);
