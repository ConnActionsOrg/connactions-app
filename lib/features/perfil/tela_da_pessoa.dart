import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/perfil_de_pessoa.dart';
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
import '../../design/widgets/estado_vazio.dart';
import 'cartao_de_atividade_feita.dart';
import 'conexoes.dart';
import 'linha_de_contadores.dart';
import 'perfil_da_pessoa.dart';

enum _AcaoDoPerfil { desconectar }

/// O perfil de uma conexão: o cabeçalho, os contadores e as atividades que ela deixou eu ver. Quem
/// não é conexão recebe 403, e a tela diz isso em vez de oferecer tentar de novo.
class TelaDaPessoa extends ConsumerStatefulWidget {
  const TelaDaPessoa({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TelaDaPessoa> createState() => _TelaDaPessoaState();
}

class _TelaDaPessoaState extends ConsumerState<TelaDaPessoa> {
  // com a chamada no ar, um 2º desconectar abriria o diálogo de novo
  bool _desconectando = false;

  Future<void> _desconectar(PerfilDePessoa perfil) async {
    final nome = perfil.pessoa.primeiroNome;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text('Desconectar de $nome?'),
        content: const Text(
          'Vocês deixam de ver o perfil um do outro. Para voltar, um dos dois precisa do código do outro.',
        ),
        // TextButton nos dois: o FilledButton do tema tem largura mínima infinita e não cabe na
        // barra de ações do diálogo
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    // antes do await: com a tela fechada no meio, a pessoa ainda sai da lista e o aviso ainda
    // sai, pelo mensageiro da raiz
    final conexoes = ref.read(conexoesProvider.notifier);
    final mensageiro = ScaffoldMessenger.of(context);
    setState(() => _desconectando = true);
    try {
      await conexoes.desconectar(widget.id);
      if (mounted) context.pop();
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Você e $nome não estão mais conectados.')),
        );
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _desconectando = false);
    }
  }

  /// Relê o perfil e, se as atividades continuam visíveis, a lista: com a visibilidade desligada no
  /// meio, a lista daria 403, e a tela já mostra o "só para si" pelo perfil novo.
  Future<void> _atualizar(PerfilDePessoa antes) async {
    try {
      ref.invalidate(perfilDaPessoaProvider(widget.id));
      final novo = await ref.read(perfilDaPessoaProvider(widget.id).future);
      if (antes.atividades != null && novo.atividades != null) {
        ref.invalidate(atividadesFeitasProvider(widget.id));
        await ref.read(atividadesFeitasProvider(widget.id).future);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilDaPessoaProvider(widget.id));
    final euId = ref.watch(perfilAtualProvider).value?.id;
    final valor = perfil.value;
    final erro = perfil.error;
    final Widget corpo;
    if (erro is ErroDaApi && erro.semAcesso) {
      // desconectados, até de outro aparelho: só o outro pode passar o código de novo
      corpo = EstadoVazio(
        icone: Symbols.person_off,
        titulo: 'Vocês não estão conectados.',
        acao: OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Voltar'),
        ),
      );
    } else if (valor == null && erro != null) {
      corpo = EstadoDeErro(
        mensagem: mensagemDoErro(erro),
        aoTentarDeNovo: () {
          ref.invalidate(perfilDaPessoaProvider(widget.id));
          ref.invalidate(atividadesFeitasProvider(widget.id));
        },
      );
    } else if (valor == null) {
      corpo = const Center(child: CircularProgressIndicator());
    } else {
      corpo = RefreshIndicator(
        onRefresh: () => _atualizar(valor),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espacos.margemDaTela,
            Espacos.md,
            Espacos.margemDaTela,
            Espacos.xl,
          ),
          children: [
            _Cabeca(perfil: valor),
            const SizedBox(height: Espacos.xl),
            ..._atividades(valor),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: Cabecalho(
        titulo: 'Perfil',
        acoes: [
          if (valor != null && erro == null && widget.id != euId)
            PopupMenuButton<_AcaoDoPerfil>(
              enabled: !_desconectando,
              icon: const Icon(Symbols.more_vert),
              onSelected: (_) => _desconectar(valor),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _AcaoDoPerfil.desconectar,
                  child: Text('Desconectar'),
                ),
              ],
            ),
        ],
      ),
      body: corpo,
    );
  }

  List<Widget> _atividades(PerfilDePessoa perfil) {
    final nome = perfil.pessoa.primeiroNome;
    if (perfil.atividades == null) {
      // a lista daria 403: nem é pedida
      return [
        EstadoVazio(
          icone: Symbols.lock,
          titulo: '$nome deixou as atividades só para si.',
        ),
      ];
    }
    final atividades = ref.watch(atividadesFeitasProvider(widget.id));
    final pagina = atividades.value;
    final erro = atividades.error;
    if (pagina == null && erro != null) {
      return [
        EstadoDeErro(
          mensagem: mensagemDoErro(erro),
          aoTentarDeNovo: () {
            ref.invalidate(perfilDaPessoaProvider(widget.id));
            ref.invalidate(atividadesFeitasProvider(widget.id));
          },
        ),
      ];
    }
    if (pagina == null) {
      return [
        const Padding(
          padding: EdgeInsets.all(Espacos.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (pagina.itens.isEmpty) {
      return [
        EstadoVazio(
          icone: Symbols.auto_stories,
          titulo: '$nome ainda não tem atividades que você possa ver.',
        ),
      ];
    }
    final agora = ref.watch(relogioProvider)();
    return [
      for (final atividade in pagina.itens) ...[
        CartaoDeAtividadeFeita(atividade: atividade, agora: agora),
        const SizedBox(height: Espacos.md),
      ],
      if (pagina.proximo != null)
        BotaoCarregarMais(
          aoCarregar: () => ref
              .read(atividadesFeitasProvider(widget.id).notifier)
              .carregarMais(),
        ),
    ];
  }
}

class _Cabeca extends StatelessWidget {
  const _Cabeca({required this.perfil});

  final PerfilDePessoa perfil;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Column(
      children: [
        Avatar(
          nome: perfil.nome,
          fotoUrl: perfil.fotoUrl,
          tamanho: 96,
          inclinado: true,
        ),
        const SizedBox(height: 12),
        Text(
          perfil.nome,
          style: tipografia.tituloMedio,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '@${perfil.handle}',
          style: tipografia.etiquetaMedia.copyWith(
            color: cores.sobreSuperficieVariante,
          ),
        ),
        if (perfil.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Espacos.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: cores.superficieMaisBaixa,
              borderRadius: BorderRadius.circular(Raios.padrao),
            ),
            child: Text(
              perfil.bio,
              style: tipografia.corpoMedio,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: Espacos.md),
        LinhaDeContadores(perfil: perfil),
      ],
    );
  }
}
