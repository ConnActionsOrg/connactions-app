import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../api/modelos/atividade_da_comunidade.dart';
import '../api/modelos/ideia.dart';
import '../design/widgets/barra_de_abas.dart';
import '../features/atividades/tela_de_propor.dart';
import '../features/comunidade/tela_da_comunidade.dart';
import '../features/diario/tela_do_diario.dart';
import '../features/entrada/tela_de_abertura.dart';
import '../features/entrada/tela_de_entrada.dart';
import '../features/feed/tela_do_feed.dart';
import '../features/ideias/tela_de_nova_ideia.dart';
import '../features/ideias/tela_do_backlog.dart';
import '../features/perfil/tela_de_editar_perfil.dart';
import '../features/perfil/tela_do_perfil.dart';
import '../features/turmas/tela_da_turma.dart';
import '../features/turmas/tela_de_entrar_na_turma.dart';
import '../features/turmas/tela_de_nova_turma.dart';
import 'sessao.dart';

/// Um GoRouter por app, num Provider: recriá-lo a cada build perderia a pilha de navegação.
final roteadorProvider = Provider<GoRouter>((ref) {
  // Cada troca de conta cutuca o roteador para reavaliar o redirect.
  final cutucao = ValueNotifier<int>(0);
  ref.listen(contaProvider, (_, _) => cutucao.value++);
  ref.onDispose(cutucao.dispose);
  // As telas empilhadas nascem no navigator da raiz: cobrem a barra de abas.
  final raiz = GlobalKey<NavigatorState>();

  final roteador = GoRouter(
    navigatorKey: raiz,
    initialLocation: '/abertura',
    refreshListenable: cutucao,
    redirect: (context, state) {
      final conta = ref.read(contaProvider);
      final local = state.matchedLocation;
      if (conta.isLoading && !conta.hasValue) {
        return local == '/abertura' ? null : '/abertura';
      }
      final logado = conta.value != null;
      if (!logado) return local == '/entrada' ? null : '/entrada';
      if (local == '/entrada' || local == '/abertura') return '/feed';
      return null;
    },
    routes: [
      GoRoute(path: '/abertura', builder: (_, _) => const TelaDeAbertura()),
      GoRoute(path: '/entrada', builder: (_, _) => const TelaDeEntrada()),
      // rotas fixas antes de /turmas/:id (Tarefa 13), senão "nova" e "entrar" virariam ids
      GoRoute(
        path: '/turmas/nova',
        parentNavigatorKey: raiz,
        builder: (_, _) => const TelaDeNovaTurma(),
      ),
      GoRoute(
        path: '/turmas/entrar',
        parentNavigatorKey: raiz,
        builder: (_, _) => const TelaDeEntrarNaTurma(),
      ),
      GoRoute(
        path: '/turmas/:id/propor',
        parentNavigatorKey: raiz,
        // o backlog e a Comunidade passam a origem no extra; sem ele, o formulário nasce vazio
        builder: (_, state) => TelaDePropor(
          turmaId: state.pathParameters['id']!,
          ideia: switch (state.extra) {
            final Ideia ideia => ideia,
            _ => null,
          },
          daComunidade: switch (state.extra) {
            final AtividadeDaComunidade atividade => atividade,
            _ => null,
          },
        ),
      ),
      GoRoute(
        path: '/turmas/:id/ideias/nova',
        parentNavigatorKey: raiz,
        builder: (_, state) =>
            TelaDeNovaIdeia(turmaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/turmas/:id/ideias',
        parentNavigatorKey: raiz,
        builder: (_, state) =>
            TelaDoBacklog(turmaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/turmas/:id',
        parentNavigatorKey: raiz,
        builder: (_, state) => TelaDaTurma(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/perfil/editar',
        parentNavigatorKey: raiz,
        builder: (_, _) => const TelaDeEditarPerfil(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => CascaDeAbas(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/feed', builder: (_, _) => const TelaDoFeed()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/diario', builder: (_, _) => const TelaDoDiario()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/comunidade',
                builder: (_, _) => const TelaDaComunidade(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/perfil', builder: (_, _) => const TelaDoPerfil()),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(roteador.dispose);
  return roteador;
});

/// As quatro abas do Stitch. O IndexedStack preserva o estado de cada uma ao alternar.
class CascaDeAbas extends StatelessWidget {
  const CascaDeAbas({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const abas = [
    AbaDaBarra(rotulo: 'Feed', icone: Symbols.local_cafe),
    AbaDaBarra(rotulo: 'Diário', icone: Symbols.auto_stories),
    AbaDaBarra(rotulo: 'Comunidade', icone: Symbols.groups_2),
    AbaDaBarra(rotulo: 'Perfil', icone: Symbols.person),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: BarraDeAbas(
      abas: abas,
      indiceAtivo: shell.currentIndex,
      aoSelecionar: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
    ),
  );
}
