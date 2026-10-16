import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/pessoa.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import 'conexoes.dart';

/// Os meus amigos, a conexão mais recente primeiro; cada um abre o perfil dele.
class TelaDeAmigos extends ConsumerWidget {
  const TelaDeAmigos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conexoes = ref.watch(conexoesProvider);
    final amigos = amigosDaConta(conexoes);
    final erro = conexoes.error;
    final List<Widget> corpo;
    if (amigos == null && erro != null) {
      corpo = [
        EstadoDeErro(
          mensagem: mensagemDoErro(erro),
          aoTentarDeNovo: () {
            // a falha pode ter nascido no perfil, que a lista espera; relido à toa, ele trocaria o
            // Perfil, embaixo desta tela, pelo indicador
            if (ref.read(perfilAtualProvider).hasError) {
              ref.invalidate(perfilAtualProvider);
            }
            ref.invalidate(conexoesProvider);
          },
        ),
      ];
    } else if (amigos == null) {
      corpo = [
        const Padding(
          padding: EdgeInsets.all(Espacos.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (amigos.isEmpty) {
      corpo = [
        EstadoVazio(
          icone: Symbols.group_add,
          titulo: 'Você ainda não tem amigos no app',
          acao: FilledButton.icon(
            onPressed: () => context.push('/amigos/conectar'),
            icon: const Icon(Symbols.person_add),
            label: const Text('Conectar amigo'),
          ),
        ),
      ];
    } else {
      corpo = [for (final pessoa in amigos) _LinhaDeAmigo(pessoa: pessoa)];
    }
    return Scaffold(
      appBar: Cabecalho(
        titulo: 'Amigos',
        acoes: [
          IconButton(
            tooltip: 'Conectar amigo',
            icon: const Icon(Symbols.person_add),
            onPressed: () => context.push('/amigos/conectar'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            ref.invalidate(conexoesProvider);
            await ref.read(conexoesProvider.future);
          } catch (e) {
            if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espacos.margemDaTela,
            Espacos.md,
            Espacos.margemDaTela,
            Espacos.xl,
          ),
          children: corpo,
        ),
      ),
    );
  }
}

class _LinhaDeAmigo extends StatelessWidget {
  const _LinhaDeAmigo({required this.pessoa});

  final Pessoa pessoa;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return InkWell(
      onTap: () => context.push('/pessoas/${pessoa.id}'),
      borderRadius: BorderRadius.circular(Raios.padrao),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacos.sm),
        child: Row(
          children: [
            Avatar(nome: pessoa.nome, fotoUrl: pessoa.fotoUrl, tamanho: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pessoa.nome,
                    style: tipografia.rotuloTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${pessoa.handle}',
                    style: tipografia.corpoPequeno.copyWith(
                      color: cores.sobreSuperficieVariante,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, color: cores.sobreSuperficieVariante),
          ],
        ),
      ),
    );
  }
}
