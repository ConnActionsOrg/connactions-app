import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/atividade.dart';
import '../../api/modelos/foto_para_enviar.dart';
import '../../api/modelos/proposta.dart';
import '../../api/modelos/registro.dart';
import '../../app/dependencias.dart';
import '../diario/diario.dart';
import '../turmas/turmas.dart';

/// A atividade aberta de uma turma, por id; nula quando não há. Só é observada com turma ativa,
/// então o perfil já existe. Toda mutação espera o build assentar (um build em voo sobrescreveria).
class AtividadeAberta extends AsyncNotifier<Atividade?> {
  AtividadeAberta(this.turmaId);

  final String turmaId;

  @override
  Future<Atividade?> build() =>
      ref.watch(apiProvider).obterAtividadeAberta(turmaId);

  Future<Atividade> lancar(Proposta proposta) async {
    await future;
    final atividade = await ref
        .read(apiProvider)
        .lancarAtividade(turmaId, proposta);
    if (ref.mounted) state = AsyncData(atividade);
    return atividade;
  }

  /// Zera a aberta, entrega a turma (com a vez nova) à lista e manda o Diário reler.
  Future<Encerramento> encerrar() async {
    final atual = await future;
    if (atual == null) {
      throw StateError('não há atividade aberta para encerrar');
    }
    final encerramento = await ref
        .read(apiProvider)
        .encerrarAtividade(atual.id);
    if (!ref.mounted) return encerramento;
    state = const AsyncData(null);
    ref.read(turmasProvider.notifier).substituir(encerramento.turma);
    ref.invalidate(diarioProvider(turmaId));
    return encerramento;
  }

  Future<Registro> registrar(FotoParaEnviar foto, String legenda) async {
    final atual = await future;
    if (atual == null) {
      throw StateError('não há atividade aberta para registrar');
    }
    final registro = await ref
        .read(apiProvider)
        .registrar(atual.id, foto: foto, legenda: legenda);
    if (ref.mounted) {
      final agora = state.value ?? atual;
      state = AsyncData(
        agora.copyWith(registros: [...agora.registros, registro]),
      );
    }
    return registro;
  }

  Future<void> apagarRegistro(String id) async {
    final atual = await future;
    if (atual == null) return;
    await ref.read(apiProvider).apagarRegistro(id);
    if (!ref.mounted) return;
    final agora = state.value ?? atual;
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
