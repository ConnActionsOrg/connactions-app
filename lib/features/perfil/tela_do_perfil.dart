import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/eu.dart';
import '../../app/dependencias.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../notificacoes/cartao_de_notificacoes_desligadas.dart';

/// Perfil próprio. É a fatia vertical da fundação: tema, login, API e banco numa tela real.
class TelaDoPerfil extends ConsumerWidget {
  const TelaDoPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilAtualProvider);
    return Scaffold(
      appBar: const Cabecalho(),
      body: switch (perfil) {
        AsyncData(:final value) when value != null => _Corpo(eu: value),
        // deslogando: o roteador troca a tela em seguida
        AsyncData() => const SizedBox.shrink(),
        // "Sair da conta" fica fora da área rolável nestes dois ramos: perfil que falha ao
        // carregar não pode prender quem já está logado.
        AsyncError(:final error) => Column(
          children: [
            Expanded(
              child: EstadoDeErro(
                mensagem: mensagemDoErro(error),
                aoTentarDeNovo: () => ref.invalidate(perfilAtualProvider),
              ),
            ),
            const _RodapeComSair(),
          ],
        ),
        _ => const Column(
          children: [
            Expanded(child: Center(child: CircularProgressIndicator())),
            _RodapeComSair(),
          ],
        ),
      },
    );
  }
}

/// Extraído para aparecer nos três estados (carregando, erro, dados) sem repetir o onPressed.
class _BotaoSair extends ConsumerWidget {
  const _BotaoSair();

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    onPressed: () async {
      try {
        await sairDaConta(
          notificador: ref.read(notificadorProvider),
          api: ref.read(apiProvider),
          autenticador: ref.read(autenticadorProvider),
        );
      } catch (_) {
        if (context.mounted) {
          mostrarAviso(context, 'Não consegui sair. Tente de novo.');
        }
      }
    },
    icon: const Icon(Symbols.logout),
    label: const Text('Sair da conta'),
  );
}

/// O mesmo rodapé dos ramos de erro e carregando (o de dados usa o botão direto no ListView).
class _RodapeComSair extends StatelessWidget {
  const _RodapeComSair();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(
      Espacos.margemDaTela,
      0,
      Espacos.margemDaTela,
      Espacos.xl,
    ),
    child: _BotaoSair(),
  );
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.eu});

  final Eu eu;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      Espacos.margemDaTela,
      Espacos.md,
      Espacos.margemDaTela,
      Espacos.xl,
    ),
    children: [
      _CartaoDeIdentidade(eu: eu),
      const SizedBox(height: Espacos.md),
      const CartaoDeNotificacoesDesligadas(),
      _CartaoDeVisibilidade(eu: eu),
      const SizedBox(height: Espacos.md),
      _CartaoDoCodigo(codigo: eu.codigoDeAmigo),
      const SizedBox(height: Espacos.xl),
      const _BotaoSair(),
    ],
  );
}

class _CartaoDeIdentidade extends StatelessWidget {
  const _CartaoDeIdentidade({required this.eu});

  final Eu eu;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      // o clipe mora aqui (não num ClipRRect por fora) para a sombra da decoration pintar sem
      // ser cortada; só o filho (o Stack) é cortado no raio do cartão.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.grande),
        boxShadow: Sombras.nivel1,
      ),
      child: Stack(
        // sem clipe próprio: um Clip.hardEdge aqui cortaria a mancha num retângulo reto antes do
        // corte arredondado do Container acontecer — o bug original, um nível abaixo.
        clipBehavior: Clip.none,
        children: [
          // a mancha âmbar do canto, como no Stitch: ancorada na borda do cartão, não no padding
          // do conteúdo (por isso fica fora do Padding abaixo).
          Positioned(
            right: -32,
            top: -32,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cores.secundariaFixa.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Espacos.cartao),
            child: Column(
              children: [
                const SizedBox(height: Espacos.sm),
                Avatar(
                  nome: eu.nome,
                  fotoUrl: eu.fotoUrl,
                  tamanho: 96,
                  inclinado: true,
                ),
                const SizedBox(height: 12),
                Text(
                  eu.nome,
                  style: tipografia.tituloMedio,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${eu.handle}',
                  style: tipografia.etiquetaMedia.copyWith(
                    color: cores.sobreSuperficieVariante,
                  ),
                ),
                if (eu.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Espacos.md,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cores.superficieMaisBaixa.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(Raios.padrao),
                    ),
                    child: Text(
                      eu.bio,
                      style: tipografia.corpoMedio,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: Espacos.sm),
                TextButton.icon(
                  onPressed: () => context.push('/perfil/editar'),
                  icon: const Icon(Symbols.edit),
                  label: const Text('Editar perfil'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoDeVisibilidade extends ConsumerWidget {
  const _CartaoDeVisibilidade({required this.eu});

  final Eu eu;

  Future<void> _trocar(
    BuildContext context,
    WidgetRef ref,
    bool visiveis,
  ) async {
    try {
      await ref
          .read(perfilAtualProvider.notifier)
          .definirVisibilidade(visiveis);
    } catch (_) {
      if (context.mounted) {
        mostrarAviso(context, 'Não consegui salvar. Tente de novo.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.padrao),
        boxShadow: Sombras.nivel1,
      ),
      padding: const EdgeInsets.all(Espacos.md),
      child: MergeSemantics(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cores.superficieContainer,
              ),
              alignment: Alignment.center,
              child: Icon(Symbols.group, size: 22, color: cores.primaria),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visibilidade das atividades',
                    style: tipografia.rotuloTitulo,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eu.atividadesVisiveis
                        ? 'Amigos conectados veem o que você concluiu.'
                        : 'Só você vê o que concluiu.',
                    style: tipografia.corpoPequeno.copyWith(
                      color: cores.sobreSuperficieVariante,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: eu.atividadesVisiveis,
              onChanged: (visiveis) => _trocar(context, ref, visiveis),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoDoCodigo extends StatelessWidget {
  const _CartaoDoCodigo({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.medio),
        boxShadow: Sombras.nivel1,
      ),
      padding: const EdgeInsets.all(Espacos.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Código de amigo',
            style: tipografia.etiquetaMedia.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          const SizedBox(height: Espacos.xs),
          Text(
            codigo,
            style: tipografia.tituloPequeno.copyWith(letterSpacing: 3),
          ),
          const SizedBox(height: Espacos.xs),
          Text(
            'Quem digitar este código no app se conecta a você.',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
        ],
      ),
    );
  }
}
