import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/atividade.dart';
import '../../api/modelos/foto_para_enviar.dart';
import '../../api/modelos/proposta.dart';
import '../../api/modelos/registro.dart';
import '../../app/assentado.dart';
import '../../app/dependencias.dart';
import '../diario/diario.dart';
import '../turmas/turmas.dart';

/// A atividade aberta de uma turma, por id; nula quando não há. Só é observada com turma ativa,
/// então o perfil já existe. Toda mutação espera o build assentar (um build em voo sobrescreveria)
/// e lê do `ref` o que vai usar antes do primeiro await: a família pode ser descartada enquanto a
/// API responde.
class AtividadeAberta extends AsyncNotifier<Atividade?>
    with EsperaOBuild<Atividade?> {
  AtividadeAberta(this.turmaId);

  final String turmaId;

  @override
  Future<Atividade?> build() =>
      ref.watch(apiProvider).obterAtividadeAberta(turmaId);

  Future<Atividade> lancar(Proposta proposta) async {
    final api = ref.read(apiProvider);
    await assentado;
    final atividade = await api.lancarAtividade(turmaId, proposta);
    if (ref.mounted) state = AsyncData(atividade);
    return atividade;
  }

  /// Zera a aberta, entrega a turma (com a vez nova) à lista e manda o Diário reler.
  Future<Encerramento> encerrar() async {
    final api = ref.read(apiProvider);
    final turmas = ref.read(turmasProvider.notifier);
    final atual = await assentado;
    if (atual == null) {
      throw StateError('não há atividade aberta para encerrar');
    }
    final encerramento = await api.encerrarAtividade(atual.id);
    // a vez já andou na API, mesmo que ninguém mais observe esta aberta
    turmas.substituir(encerramento.turma);
    if (!ref.mounted) return encerramento;
    state = const AsyncData(null);
    ref.invalidate(diarioProvider(turmaId));
    return encerramento;
  }

  Future<Registro> registrar(FotoParaEnviar foto, String legenda) async {
    final api = ref.read(apiProvider);
    final atual = await assentado;
    if (atual == null) {
      throw StateError('não há atividade aberta para registrar');
    }
    final registro = await api.registrar(
      atual.id,
      foto: foto,
      legenda: legenda,
    );
    if (ref.mounted) {
      final agora = state.value;
      // um encerrar que chegou antes já zerou a aberta: não a ressuscitar com este registro
      if (agora != null && agora.id == atual.id) {
        state = AsyncData(
          agora.copyWith(registros: [...agora.registros, registro]),
        );
      }
    }
    return registro;
  }

  Future<void> apagarRegistro(String id) async {
    final api = ref.read(apiProvider);
    final atual = await assentado;
    if (atual == null) return;
    await api.apagarRegistro(id);
    if (!ref.mounted) return;
    final agora = state.value;
    // encerrada enquanto a API respondia: não ressuscitar a aberta
    if (agora == null || agora.id != atual.id) return;
    state = AsyncData(
      agora.copyWith(
        registros: [
          for (final r in agora.registros)
            if (r.id != id) r,
        ],
      ),
    );
  }
}

// Sem retry automático: a tela oferece "Tentar de novo".
final atividadeAbertaProvider = AsyncNotifierProvider.autoDispose
    .family<AtividadeAberta, Atividade?, String>(
      AtividadeAberta.new,
      retry: (_, _) => null,
    );

/// O estado mudou embaixo de mim (409): relê a aberta e a lista de turmas, porque encerrar move a vez.
void invalidarRodada(WidgetRef ref, String turmaId) {
  ref.invalidate(atividadeAbertaProvider(turmaId));
  ref.invalidate(turmasProvider);
}
