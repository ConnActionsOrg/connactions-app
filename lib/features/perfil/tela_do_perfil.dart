import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/eu.dart';
import '../../app/dependencias.dart';
import '../../app/relogio.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/botao_carregar_mais.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../notificacoes/cartao_de_notificacoes_desligadas.dart';
import 'cartao_de_atividade_feita.dart';
import 'codigo_de_amigo.dart';
import 'codigo_em_destaque.dart';
import 'conexoes.dart';
import 'fileira_de_amigos.dart';
import 'linha_de_contadores.dart';
import 'perfil_da_pessoa.dart';

/// Perfil próprio: a identidade com os contadores, os amigos, as atividades concluídas e o convite
/// para chamar mais amigos. Cada seção carrega e falha sozinha, sem derrubar as outras.
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

class _Corpo extends ConsumerWidget {
  const _Corpo({required this.eu});

  final Eu eu;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    // o perfil fica de fora: a recarga dele trocaria a tela inteira pelo indicador
    onRefresh: () async {
      try {
        await Future.wait<Object?>([
          ref.refresh(conexoesProvider.future),
          ref.refresh(perfilDaPessoaProvider(eu.id).future),
          ref.refresh(atividadesFeitasProvider(eu.id).future),
        ]);
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
      children: [
        _CartaoDeIdentidade(eu: eu),
        const SizedBox(height: Espacos.md),
        const CartaoDeNotificacoesDesligadas(),
        _CartaoDeVisibilidade(eu: eu),
        const SizedBox(height: Espacos.xl),
        const _Amigos(),
        const SizedBox(height: Espacos.xl),
        _MinhasAtividades(eu: eu),
        const SizedBox(height: Espacos.xl),
        _ChamarMaisAmigos(codigo: eu.codigoDeAmigo),
        const SizedBox(height: Espacos.xl),
        const _BotaoSair(),
      ],
    ),
  );
}

class _CartaoDeIdentidade extends ConsumerWidget {
  const _CartaoDeIdentidade({required this.eu});

  final Eu eu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final contadores = ref.watch(perfilDaPessoaProvider(eu.id));
    final Widget? linha;
    if (contadores.value case final perfil?) {
      linha = LinhaDeContadores(perfil: perfil);
    } else if (contadores.hasError) {
      // com erro a linha some, e o resto do perfil segue usável
      linha = null;
    } else {
      linha = const LinhaDeContadores.carregando();
    }
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
                if (linha != null) ...[
                  const SizedBox(height: Espacos.md),
                  linha,
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

/// O título com o "Ver todos (N)" e a fileira. O cartão "Conectar amigo" fica até no erro: é o
/// caminho que a mensagem do código manda seguir (Perfil › Conectar amigo).
class _Amigos extends ConsumerWidget {
  const _Amigos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final conexoes = ref.watch(conexoesProvider);
    final amigos = amigosDaConta(conexoes);
    final erro = amigos == null ? conexoes.error : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Amigos', style: tipografia.tituloPequeno)),
            if (amigos != null && amigos.isNotEmpty)
              // Flexible: com a fonte grande o botão quebra a linha em vez de estourar a fileira
              Flexible(
                child: TextButton(
                  onPressed: () => context.push('/amigos'),
                  child: Text('Ver todos (${amigos.length})'),
                ),
              ),
          ],
        ),
        const SizedBox(height: Espacos.sm),
        FileiraDeAmigos(
          amigos: amigos ?? const [],
          carregando: amigos == null && erro == null,
        ),
        if (erro != null) ...[
          const SizedBox(height: Espacos.sm),
          Text(
            'Não consegui carregar seus amigos.',
            style: tipografia.corpoMedio.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(conexoesProvider),
            child: const Text('Tentar de novo'),
          ),
        ],
      ],
    );
  }
}

class _MinhasAtividades extends ConsumerWidget {
  const _MinhasAtividades({required this.eu});

  final Eu eu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final atividades = ref.watch(atividadesFeitasProvider(eu.id));
    final pagina = atividades.value;
    final erro = pagina == null ? atividades.error : null;
    final agora = ref.watch(relogioProvider)();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Minhas atividades concluídas', style: tipografia.tituloPequeno),
        const SizedBox(height: Espacos.md),
        if (erro != null) ...[
          Text(
            mensagemDoErro(erro),
            style: tipografia.corpoMedio.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => ref.invalidate(atividadesFeitasProvider(eu.id)),
              child: const Text('Tentar de novo'),
            ),
          ),
        ] else if (pagina == null)
          const Padding(
            padding: EdgeInsets.all(Espacos.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (pagina.itens.isEmpty)
          Text(
            'Suas atividades encerradas aparecem aqui.',
            style: tipografia.corpoMedio.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          )
        else ...[
          for (final atividade in pagina.itens) ...[
            CartaoDeAtividadeFeita(atividade: atividade, agora: agora),
            const SizedBox(height: Espacos.md),
          ],
          if (pagina.proximo != null)
            BotaoCarregarMais(
              aoCarregar: () => ref
                  .read(atividadesFeitasProvider(eu.id).notifier)
                  .carregarMais(),
            ),
        ],
      ],
    );
  }
}

/// O meu código de amigo, com o botão que manda o convite pronto.
class _ChamarMaisAmigos extends ConsumerWidget {
  const _ChamarMaisAmigos({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cores.primariaFixa, cores.secundariaFixa],
        ),
        borderRadius: BorderRadius.circular(Raios.medio),
        boxShadow: Sombras.nivel1,
      ),
      padding: const EdgeInsets.all(Espacos.cartao),
      // em coluna: o tema dá largura mínima infinita aos botões cheios, e numa Row eles estourariam
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chamar mais amigos?',
            style: tipografia.tituloPequeno.copyWith(
              color: cores.sobrePrimariaFixa,
            ),
          ),
          const SizedBox(height: Espacos.xs),
          Text(
            'Compartilhe seu código para criar novas conexões.',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobrePrimariaFixaVariante,
            ),
          ),
          const SizedBox(height: Espacos.md),
          CodigoEmDestaque(codigo, cor: cores.sobrePrimariaFixa),
          const SizedBox(height: Espacos.md),
          FilledButton.icon(
            onPressed: () => ref
                .read(compartilhadorProvider)
                .compartilhar(textoDoCodigoDeAmigo(codigo)),
            icon: const Icon(Symbols.share),
            label: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }
}
