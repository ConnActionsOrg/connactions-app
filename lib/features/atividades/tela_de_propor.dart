import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/atividade.dart';
import '../../api/modelos/atividade_da_comunidade.dart';
import '../../api/modelos/ideia.dart';
import '../../api/modelos/proposta.dart';
import '../../app/relogio.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/botao_carregar_mais.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/disco_de_emoji.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../comunidade/comunidade.dart';
import '../comunidade/texto_de_inspiradas.dart';
import '../ideias/cartao_de_ideia.dart';
import '../ideias/ideias.dart';
import '../turmas/turmas.dart';
import 'atividade_aberta.dart';

/// Uma regra por linha: apara e descarta as vazias.
List<String> regrasDoTexto(String texto) => [
  for (final linha in texto.split('\n'))
    if (linha.trim().isNotEmpty) linha.trim(),
];

/// O formulário de quem está na vez. Fora da vez, ou com atividade aberta (deep link, estado
/// velho), mostra o estado vazio em vez do formulário.
class TelaDePropor extends ConsumerStatefulWidget {
  const TelaDePropor({
    super.key,
    required this.turmaId,
    this.ideia,
    this.daComunidade,
  });

  final String turmaId;

  /// De onde veio quem abriu a tela (o backlog ou a Comunidade): já vem preenchida, como se a
  /// pessoa tivesse escolhido ali dentro.
  final Ideia? ideia;
  final AtividadeDaComunidade? daComunidade;

  @override
  ConsumerState<TelaDePropor> createState() => _TelaDeProporState();
}

class _TelaDeProporState extends ConsumerState<TelaDePropor> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _regras = TextEditingController();
  FormatoDeAtividade _formato = FormatoDeAtividade.grupo;
  DateTime? _prazo;
  bool _publica = true;
  bool _lancando = false;
  _Aba _aba = _Aba.doZero;

  /// O vínculo: no máximo um dos dois. Só a origem é guardada; o texto é da pessoa e pode mudar.
  Ideia? _ideia;
  AtividadeDaComunidade? _daComunidade;

  static final _formatoDaData = DateFormat("EEE, d 'de' MMM", 'pt_BR');

  @override
  void initState() {
    super.initState();
    final ideia = widget.ideia;
    final daComunidade = widget.daComunidade;
    if (ideia != null) _usarIdeia(ideia);
    if (daComunidade != null) _usarDaComunidade(daComunidade);
  }

  /// Escolher preenche o formulário; o formato só muda quando a origem tem um.
  void _preencher({
    required String titulo,
    required String descricao,
    required List<String> regras,
    FormatoDeAtividade? formato,
  }) {
    _titulo.text = titulo;
    _descricao.text = descricao;
    _regras.text = regras.join('\n');
    if (formato != null) _formato = formato;
    _aba = _Aba.doZero;
  }

  void _usarIdeia(Ideia ideia) {
    _preencher(
      titulo: ideia.titulo,
      descricao: ideia.descricao,
      regras: ideia.regras,
      formato: ideia.formato,
    );
    _ideia = ideia;
    _daComunidade = null;
  }

  void _usarDaComunidade(AtividadeDaComunidade atividade) {
    _preencher(
      titulo: atividade.titulo,
      descricao: atividade.descricao,
      regras: atividade.regras,
      formato: atividade.formato,
    );
    _daComunidade = atividade;
    _ideia = null;
  }

  String? _rotuloDaOrigem(String? euId) {
    final ideia = _ideia;
    if (ideia != null) {
      return ideia.autor.id == euId
          ? 'Sua ideia'
          : 'Ideia de ${ideia.autor.primeiroNome}';
    }
    final daComunidade = _daComunidade;
    if (daComunidade != null) {
      return 'Da Comunidade · ${daComunidade.turmaEmoji} ${daComunidade.turmaNome}';
    }
    return null;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _regras.dispose();
    super.dispose();
  }

  String? get _erroDasRegras {
    final regras = regrasDoTexto(_regras.text);
    if (regras.length > 10) return 'No máximo 10 regras.';
    // a API conta pontos de código (runes), não unidades UTF-16: um emoji vale 1
    if (regras.any((r) => r.runes.length > 100)) {
      return 'Cada regra tem até 100 caracteres.';
    }
    return null;
  }

  bool get _podeLancar =>
      !_lancando && _titulo.text.trim().isNotEmpty && _erroDasRegras == null;

  Future<void> _escolherPrazo() async {
    // Sem largar o foco, o seletor devolve o teclado ao título ao fechar e a lista rola até lá.
    FocusManager.instance.primaryFocus?.unfocus();
    final hoje = ref.read(relogioProvider)();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _prazo ?? inicio,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 365)),
    );
    if (escolhida == null || !mounted) return;
    // o fim do dia escolhido, no fuso do aparelho; a API guarda em UTC
    setState(
      () => _prazo = DateTime(
        escolhida.year,
        escolhida.month,
        escolhida.day,
        23,
        59,
        59,
      ),
    );
  }

  Future<void> _lancar() async {
    setState(() => _lancando = true);
    // capturado antes de navegar: o aviso aparece no Feed, não nesta tela que vai fechar
    final mensageiro = ScaffoldMessenger.of(context);
    final proposta = Proposta(
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      regras: regrasDoTexto(_regras.text),
      formato: _formato,
      publica: _publica,
      prazo: _prazo,
      origemIdeiaId: _ideia?.id,
      origemAtividadeId: _daComunidade?.id,
    );
    try {
      await ref
          .read(atividadeAbertaProvider(widget.turmaId).notifier)
          .lancar(proposta);
      if (!mounted) return;
      context.pop();
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Atividade lançada!')));
    } on ErroDaApi catch (e) {
      if (!mounted) return;
      if (e.ideiaIndisponivel) {
        // alguém usou ou apagou a ideia: a tela fica, o texto fica e a pessoa pode lançá-lo como
        // ideia sua; o backlog é relido na próxima visita
        setState(() => _ideia = null);
        ref.invalidate(ideiasProvider(widget.turmaId));
        mostrarAviso(context, e.mensagem);
      } else if (e.conflito) {
        // a vez passou ou alguém lançou antes: recarrega o que o Feed mostra e volta
        invalidarRodada(ref.invalidate, widget.turmaId);
        context.pop();
        mensageiro
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.mensagem)));
      } else {
        mostrarAviso(context, e.mensagem);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _lancando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final turma = ref
        .watch(turmasProvider)
        .value
        ?.where((t) => t.id == widget.turmaId)
        .firstOrNull;
    final euId = ref.watch(perfilAtualProvider).value?.id;
    final aberta = ref.watch(atividadeAbertaProvider(widget.turmaId)).value;
    // enquanto lança, a aberta passa a existir um instante antes do pop: não trocar a tela por baixo
    final bloqueada =
        !_lancando &&
        (turma == null || turma.vezDe.id != euId || aberta != null);
    if (bloqueada) {
      return Scaffold(
        appBar: const Cabecalho(titulo: 'Propor atividade'),
        body: EstadoVazio(
          icone: Symbols.hourglass_top,
          titulo: 'Ainda não é a sua vez',
          texto: 'Quando a vez chegar, o Feed avisa.',
          acao: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Voltar'),
          ),
        ),
      );
    }
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final prazo = _prazo;
    final rotuloDaOrigem = _rotuloDaOrigem(euId);
    return Scaffold(
      appBar: const Cabecalho(titulo: 'Propor atividade'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacos.margemDaTela,
          Espacos.md,
          Espacos.margemDaTela,
          Espacos.xl,
        ),
        children: [
          const _Heroi(),
          const SizedBox(height: Espacos.md),
          _Abas(aba: _aba, aoTrocar: (aba) => setState(() => _aba = aba)),
          const SizedBox(height: Espacos.lg),
          if (_aba == _Aba.backlog)
            _AbaDoBacklog(
              turmaId: widget.turmaId,
              euId: euId,
              aoEscolher: (ideia) => setState(() => _usarIdeia(ideia)),
            )
          else if (_aba == _Aba.comunidade)
            _AbaDaComunidade(
              aoEscolher: (atividade) =>
                  setState(() => _usarDaComunidade(atividade)),
            )
          else ...[
            _Etapa(
              numero: 1,
              titulo: 'O que vamos fazer?',
              children: [
                if (rotuloDaOrigem != null) ...[
                  _ChipDaOrigem(
                    rotulo: rotuloDaOrigem,
                    aoDesfazer: () => setState(() {
                      _ideia = null;
                      _daComunidade = null;
                    }),
                  ),
                  const SizedBox(height: Espacos.md),
                ],
                TextField(
                  controller: _titulo,
                  autofocus: true,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome da atividade',
                    hintText: 'Noite de jogos & massas',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Espacos.md),
                TextField(
                  controller: _descricao,
                  maxLength: 1000,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Como vai funcionar?',
                    hintText: 'Cada um leva um ingrediente surpresa...',
                  ),
                ),
                const SizedBox(height: Espacos.md),
                TextField(
                  controller: _regras,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Regras (opcional), uma por linha',
                    hintText: 'Pelo menos um item por pessoa',
                    errorText: _erroDasRegras,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Espacos.md),
                Text('Formato', style: tipografia.rotuloTitulo),
                const SizedBox(height: Espacos.sm),
                Row(
                  children: [
                    Expanded(
                      child: _Opcao(
                        icone: Symbols.groups,
                        titulo: 'Em grupo',
                        subtitulo: 'Todos juntos ao mesmo tempo',
                        selecionada: _formato == FormatoDeAtividade.grupo,
                        aoTocar: () =>
                            setState(() => _formato = FormatoDeAtividade.grupo),
                      ),
                    ),
                    const SizedBox(width: Espacos.sm),
                    Expanded(
                      child: _Opcao(
                        icone: Symbols.person,
                        titulo: 'Individual',
                        subtitulo: 'Cada um no seu ritmo',
                        selecionada: _formato == FormatoDeAtividade.individual,
                        aoTocar: () => setState(
                          () => _formato = FormatoDeAtividade.individual,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Espacos.md),
            _Etapa(
              numero: 2,
              titulo: 'Prazo',
              children: [
                Text(
                  'Quanto tempo a turma tem para realizar e registrar?',
                  style: tipografia.corpoPequeno.copyWith(
                    color: cores.sobreSuperficieVariante,
                  ),
                ),
                const SizedBox(height: Espacos.sm),
                Row(
                  children: [
                    Expanded(
                      child: _Opcao(
                        icone: Symbols.hourglass_disabled,
                        titulo: 'Sem pressa',
                        subtitulo: 'Quando der',
                        selecionada: prazo == null,
                        aoTocar: () => setState(() => _prazo = null),
                      ),
                    ),
                    const SizedBox(width: Espacos.sm),
                    Expanded(
                      child: _Opcao(
                        icone: Symbols.calendar_month,
                        titulo: prazo == null
                            ? 'Definir data'
                            : 'até ${_formatoDaData.format(prazo)}',
                        subtitulo: prazo == null
                            ? 'Escolher no calendário'
                            : 'Toque para trocar',
                        selecionada: prazo != null,
                        aoTocar: _escolherPrazo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Espacos.md),
            _Etapa(
              numero: 3,
              titulo: 'Privacidade',
              children: [
                SwitchListTile(
                  value: _publica,
                  onChanged: (v) => setState(() => _publica = v),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permitir na Comunidade'),
                  subtitle: const Text(
                    'Outros grupos poderão se inspirar e ver as fotos no feed global.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espacos.xl),
            FilledButton(
              onPressed: _podeLancar ? _lancar : null,
              child: _lancando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lançar atividade'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Heroi extends StatelessWidget {
  const _Heroi();

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      decoration: BoxDecoration(
        color: cores.primaria,
        borderRadius: BorderRadius.circular(Raios.medio),
      ),
      padding: const EdgeInsets.all(Espacos.cartao),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'É a sua vez de propor!',
            style: tipografia.tituloMedio.copyWith(color: cores.sobrePrimaria),
          ),
          const SizedBox(height: Espacos.xs),
          Text(
            'Deixe sua imaginação voar e surpreenda o grupo com uma dinâmica memorável.',
            style: tipografia.corpoMedio.copyWith(color: cores.primariaFixa),
          ),
        ],
      ),
    );
  }
}

/// Cartão numerado de cada etapa do Stitch.
class _Etapa extends StatelessWidget {
  const _Etapa({
    required this.numero,
    required this.titulo,
    required this.children,
  });

  final int numero;
  final String titulo;
  final List<Widget> children;

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
      // O SwitchListTile pinta o toque no Material mais próximo: sem este, a cor do Container o
      // esconderia (e o Flutter reprova a árvore em debug).
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(Espacos.cartao),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cores.secundariaFixa,
                    ),
                    alignment: Alignment.center,
                    child: Text('$numero', style: tipografia.etiquetaMedia),
                  ),
                  const SizedBox(width: Espacos.sm),
                  Expanded(
                    child: Text(titulo, style: tipografia.tituloPequeno),
                  ),
                ],
              ),
              const SizedBox(height: Espacos.md),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão selecionável (formato e prazo): terracota quando escolhido, neutro quando não.
class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.selecionada,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final frente = selecionada ? cores.sobrePrimaria : cores.sobreSuperficie;
    return Semantics(
      button: true,
      selected: selecionada,
      child: Material(
        color: selecionada ? cores.primaria : cores.superficieContainer,
        borderRadius: BorderRadius.circular(Raios.padrao),
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(Raios.padrao),
          child: Padding(
            padding: const EdgeInsets.all(Espacos.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icone, color: frente),
                    const Spacer(),
                    if (selecionada)
                      Icon(Symbols.check_circle, size: 18, color: frente),
                  ],
                ),
                const SizedBox(height: Espacos.sm),
                Text(
                  titulo,
                  style: tipografia.rotuloTitulo.copyWith(color: frente),
                ),
                Text(
                  subtitulo,
                  style: tipografia.corpoPequeno.copyWith(
                    color: selecionada
                        ? cores.primariaFixa
                        : cores.sobreSuperficieVariante,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Aba { doZero, backlog, comunidade }

/// "Do zero" é o formulário; as outras duas são de onde vir com uma ideia pronta.
class _Abas extends StatelessWidget {
  const _Abas({required this.aba, required this.aoTrocar});

  final _Aba aba;
  final ValueChanged<_Aba> aoTrocar;

  @override
  Widget build(BuildContext context) => SegmentedButton<_Aba>(
    segments: [
      ButtonSegment(value: _Aba.doZero, label: _Rotulo('Do zero')),
      ButtonSegment(value: _Aba.backlog, label: _Rotulo('Backlog')),
      ButtonSegment(value: _Aba.comunidade, label: _Rotulo('Comunidade')),
    ],
    selected: {aba},
    showSelectedIcon: false,
    onSelectionChanged: (escolhida) => aoTrocar(escolhida.first),
  );
}

/// Três segmentos de largura igual não comportam "Comunidade" num celular: a fonte encolhe em vez
/// de a palavra quebrar.
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(texto, maxLines: 1, softWrap: false),
  );
}

/// De onde veio o que está no formulário. O ✕ desfaz o vínculo e mantém o texto.
class _ChipDaOrigem extends StatelessWidget {
  const _ChipDaOrigem({required this.rotulo, required this.aoDesfazer});

  final String rotulo;
  final VoidCallback aoDesfazer;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: InputChip(
      avatar: const Icon(Symbols.lightbulb, size: 18),
      label: Text(rotulo),
      onDeleted: aoDesfazer,
      deleteIcon: const Icon(Symbols.close, size: 18),
      deleteButtonTooltipMessage: 'Desfazer a origem',
    ),
  );
}

/// As ideias livres da turma, para escolher uma. Quem escreve apaga na tela do backlog, não aqui.
class _AbaDoBacklog extends ConsumerWidget {
  const _AbaDoBacklog({
    required this.turmaId,
    required this.euId,
    required this.aoEscolher,
  });

  final String turmaId;
  final String? euId;
  final ValueChanged<Ideia> aoEscolher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideias = ref.watch(ideiasProvider(turmaId));
    final lista = ideias.value;
    final erro = ideias.error;
    if (lista == null && erro != null) {
      return EstadoDeErro(
        mensagem: mensagemDoErro(erro),
        aoTentarDeNovo: () => ref.invalidate(ideiasProvider(turmaId)),
      );
    }
    if (lista == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lista.isEmpty) {
      return const EstadoVazio(
        icone: Symbols.lightbulb,
        titulo: 'O backlog da turma está vazio',
        texto: 'As ideias que a turma guardar aparecem aqui.',
      );
    }
    return Column(
      children: [
        for (final ideia in lista) ...[
          CartaoDeIdeia(
            ideia: ideia,
            souEu: ideia.autor.id == euId,
            aoProporEsta: () => aoEscolher(ideia),
          ),
          const SizedBox(height: Espacos.md),
        ],
      ],
    );
  }
}

/// A Comunidade em versão compacta, para escolher uma atividade como ponto de partida.
class _AbaDaComunidade extends ConsumerWidget {
  const _AbaDaComunidade({required this.aoEscolher});

  final ValueChanged<AtividadeDaComunidade> aoEscolher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagina = ref.watch(comunidadeProvider);
    final itens = pagina.value?.itens;
    final erro = pagina.error;
    if (itens == null && erro != null) {
      return EstadoDeErro(
        mensagem: mensagemDoErro(erro),
        aoTentarDeNovo: () => ref.invalidate(comunidadeProvider),
      );
    }
    if (itens == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (itens.isEmpty) {
      return const EstadoVazio(
        icone: Symbols.groups_2,
        titulo: 'A comunidade ainda está quieta',
        texto:
            'Atividades públicas das outras turmas vão aparecer aqui para inspirar a sua.',
      );
    }
    return Column(
      children: [
        for (final atividade in itens) ...[
          _CartaoCompactoDaComunidade(
            atividade: atividade,
            aoUsar: () => aoEscolher(atividade),
          ),
          const SizedBox(height: Espacos.md),
        ],
        if (pagina.value?.proximo != null)
          BotaoCarregarMais(
            aoCarregar: () =>
                ref.read(comunidadeProvider.notifier).carregarMais(),
          ),
      ],
    );
  }
}

class _CartaoCompactoDaComunidade extends StatelessWidget {
  const _CartaoCompactoDaComunidade({
    required this.atividade,
    required this.aoUsar,
  });

  final AtividadeDaComunidade atividade;
  final VoidCallback aoUsar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final inspiradas = textoDeInspiradas(atividade.inspiradas);
    return Container(
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.medio),
        boxShadow: Sombras.nivel1,
      ),
      padding: const EdgeInsets.all(Espacos.cartao),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DiscoDeEmoji(emoji: atividade.turmaEmoji, tamanho: 32),
              const SizedBox(width: Espacos.sm),
              Expanded(
                child: Text(
                  atividade.turmaNome,
                  style: tipografia.rotuloTitulo,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacos.sm),
          Text(atividade.titulo, style: tipografia.tituloPequeno),
          if (atividade.descricao.isNotEmpty) ...[
            const SizedBox(height: Espacos.xs),
            Text(
              atividade.descricao,
              style: tipografia.corpoMedio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (inspiradas != null) ...[
            const SizedBox(height: Espacos.sm),
            Text(
              inspiradas,
              style: tipografia.corpoPequeno.copyWith(
                color: cores.sobreSuperficieVariante,
              ),
            ),
          ],
          const SizedBox(height: Espacos.md),
          FilledButton(onPressed: aoUsar, child: const Text('Usar esta ideia')),
        ],
      ),
    );
  }
}
