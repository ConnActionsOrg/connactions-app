import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/ideia.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';

/// Quantas ideias livres cada pessoa pode guardar numa turma (a API recusa a 6ª com 409).
const tetoDeIdeias = 5;

/// As ideias livres do backlog de uma turma, da mais nova para a mais antiga. Toda mutação espera
/// o build assentar e lê o `apiProvider` antes do primeiro await: a família pode ser descartada
/// enquanto a API responde.
class Ideias extends AsyncNotifier<List<Ideia>> with EsperaOBuild<List<Ideia>> {
  Ideias(this.turmaId);

  final String turmaId;

  @override
  Future<List<Ideia>> build() => ref.watch(apiProvider).listarIdeias(turmaId);

  Future<Ideia> criar({required String titulo, String descricao = ''}) async {
    final api = ref.read(apiProvider);
    await assentado;
    final ideia = await api.criarIdeia(
      turmaId,
      titulo: titulo,
      descricao: descricao,
    );
    _naFrente(ideia);
    return ideia;
  }

  Future<Ideia> salvarDaComunidade(String atividadeId) async {
    final api = ref.read(apiProvider);
    await assentado;
    final ideia = await api.salvarDaComunidade(atividadeId, turmaId: turmaId);
    _naFrente(ideia);
    return ideia;
  }

  Future<void> apagar(String id) async {
    final api = ref.read(apiProvider);
    await assentado;
    await api.apagarIdeia(id);
    if (!ref.mounted) return;
    state = AsyncData([
      for (final i in state.value ?? const <Ideia>[])
        if (i.id != id) i,
    ]);
  }

  /// Uma recarga que chegou durante a chamada já pode trazer a ideia: nunca duplica.
  void _naFrente(Ideia ideia) {
    if (!ref.mounted) return;
    state = AsyncData([
      ideia,
      for (final i in state.value ?? const <Ideia>[])
        if (i.id != ideia.id) i,
    ]);
  }
}

// Sem retry automático: a tela oferece "Tentar de novo".
final ideiasProvider = AsyncNotifierProvider.autoDispose
    .family<Ideias, List<Ideia>, String>(Ideias.new, retry: (_, _) => null);

/// O "N/5" do cartão do backlog. A lista só tem as livres da turma, então conta as minhas.
int minhasLivres(List<Ideia> ideias, String euId) =>
    ideias.where((i) => i.autor.id == euId).length;

/// O "Salva ✓" do cartão da Comunidade: a turma já guarda essa atividade como ideia livre.
bool guardada(List<Ideia> ideias, String atividadeId) =>
    ideias.any((i) => i.origemAtividadeId == atividadeId);
