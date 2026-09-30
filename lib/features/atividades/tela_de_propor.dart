import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/atividade.dart';
import '../../api/modelos/proposta.dart';
import '../../app/relogio.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../../design/widgets/estado_vazio.dart';
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
  const TelaDePropor({super.key, required this.turmaId});

  final String turmaId;

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

  static final _formatoDaData = DateFormat("EEE, d 'de' MMM", 'pt_BR');

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
      if (e.conflito) {
        // a vez passou ou alguém lançou antes: recarrega o que o Feed mostra e volta
        invalidarRodada(ref, widget.turmaId);
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
          const SizedBox(height: Espacos.lg),
          _Etapa(
            numero: 1,
            titulo: 'O que vamos fazer?',
            children: [
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
