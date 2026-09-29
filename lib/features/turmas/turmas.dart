import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/modelos/turma.dart';
import '../../app/dependencias.dart';
import '../../app/sessao.dart';
import 'turma_ativa.dart';

/// Minhas turmas. Espera o perfil antes de listar: garante o cadastro (POST /eu) antes de qualquer
/// rota com ExigirPerfil, e faz o Feed consultar a API ao abrir.
class Turmas extends AsyncNotifier<List<Turma>> {
  @override
  Future<List<Turma>> build() async {
    final eu = await ref.watch(perfilAtualProvider.future);
    if (eu == null) return const [];
    return ref.watch(apiProvider).listarTurmas();
  }

  Future<Turma> criar({required String nome, required String emoji}) async {
    await future; // um build em voo sobrescreveria o que gravarmos abaixo
    final turma = await ref
        .read(apiProvider)
        .criarTurma(nome: nome, emoji: emoji);
    if (!ref.mounted) return turma;
    substituir(turma);
    await ref.read(turmaAtivaIdProvider.notifier).definir(turma.id);
    return turma;
  }

  Future<Turma> entrar(String codigo) async {
    await future; // um build em voo sobrescreveria o que gravarmos abaixo
    final turma = await ref.read(apiProvider).entrarNaTurma(codigo: codigo);
    if (!ref.mounted) return turma;
    substituir(turma);
    await ref.read(turmaAtivaIdProvider.notifier).definir(turma.id);
    return turma;
  }

  Future<void> sair(String id) async {
    await future; // um build em voo sobrescreveria o que gravarmos abaixo
    await ref.read(apiProvider).sairDaTurma(id);
    if (!ref.mounted) return;
    final atuais = state.value ?? const <Turma>[];
    state = AsyncData([
      for (final turma in atuais)
        if (turma.id != id) turma,
    ]);
  }

  Future<Turma> regenerarConvite(String id) async {
    await future; // um build em voo sobrescreveria o que gravarmos abaixo
    final turma = await ref.read(apiProvider).regenerarConvite(id);
    if (ref.mounted) substituir(turma);
    return turma;
  }

  /// Substitui a turma de mesmo id ou acrescenta no fim: a lista nunca duplica. Quem encerra uma
  /// atividade entrega aqui a turma com a vez nova.
  void substituir(Turma turma) {
    final novas = [...?state.value];
    final indice = novas.indexWhere((t) => t.id == turma.id);
    if (indice < 0) {
      novas.add(turma);
    } else {
      novas[indice] = turma;
    }
    state = AsyncData(novas);
  }
}

// Sem retry automático: a tela oferece "Tentar de novo" em vez de martelar a API sozinha.
final turmasProvider = AsyncNotifierProvider<Turmas, List<Turma>>(
  Turmas.new,
  retry: (_, _) => null,
);

/// Derivado, sem efeito colateral: um id órfão só é sobrescrito quando alguém chama `definir`.
final turmaAtivaProvider = Provider<Turma?>(
  (ref) => turmaAtiva(
    ref.watch(turmasProvider).value,
    ref.watch(turmaAtivaIdProvider),
  ),
);
