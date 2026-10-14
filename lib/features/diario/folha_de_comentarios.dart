import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/comentario.dart';
import '../../app/relogio.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/estado_de_erro.dart';
import '../../design/widgets/estado_vazio.dart';
import '../atividades/tempo.dart';
import 'comentarios.dart';
import 'diario.dart';

Future<void> mostrarFolhaDeComentarios(
  BuildContext context, {
  required String turmaId,
  required String atividadeId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  builder: (_) =>
      FolhaDeComentarios(alvo: (turmaId: turmaId, atividadeId: atividadeId)),
);

/// Os comentários de uma atividade encerrada e o campo para escrever o seu. Toda falha aparece
/// aqui dentro: o SnackBar nasce no Scaffold de baixo e ficaria atrás da folha.
class FolhaDeComentarios extends ConsumerStatefulWidget {
  const FolhaDeComentarios({super.key, required this.alvo});

  final AtividadeDoDiario alvo;

  @override
  ConsumerState<FolhaDeComentarios> createState() => _FolhaDeComentariosState();
}

class _FolhaDeComentariosState extends ConsumerState<FolhaDeComentarios> {
  final _texto = TextEditingController();
  final _rolagem = ScrollController();
  var _enviando = false;
  var _carregandoMais = false;
  String? _erro;

  @override
  void dispose() {
    _texto.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  Comentarios get _notifier =>
      ref.read(comentariosProvider(widget.alvo).notifier);

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _notifier.comentar(_texto.text);
      _texto.clear();
      // o comentário novo entra no fim: leva a lista até ele
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_rolagem.hasClients) {
          _rolagem.jumpTo(_rolagem.position.maxScrollExtent);
        }
      });
    } catch (e) {
      // o texto fica no campo: quem digitou não perde o que escreveu
      if (mounted) setState(() => _erro = mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _carregarMais() async {
    setState(() {
      _carregandoMais = true;
      _erro = null;
    });
    try {
      await _notifier.carregarMais();
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  Future<void> _apagar(Comentario comentario) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Apagar seu comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _erro = null);
    try {
      await _notifier.apagar(comentario.id);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDoErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final comentarios = ref.watch(comentariosProvider(widget.alvo));
    // o total é o do cartão: postar e apagar o acertam por lá
    final total = ref.watch(
      diarioProvider(widget.alvo.turmaId).select(
        (p) =>
            p.value?.itens
                .where((i) => i.atividade.id == widget.alvo.atividadeId)
                .firstOrNull
                ?.totalDeComentarios ??
            0,
      ),
    );
    final pagina = comentarios.value;
    final podeEnviar = !_enviando && _texto.text.trim().isNotEmpty;

    // erro, vazio e carregando ficam num ListView: cada um tem a altura do próprio conteúdo e rola se
    // a folha estiver curta (celular baixo, fonte grande), em vez de estourar numa caixa de altura fixa
    final Widget corpo;
    if (pagina == null && comentarios.hasError) {
      corpo = ListView(
        shrinkWrap: true,
        children: [
          EstadoDeErro(
            mensagem: mensagemDoErro(comentarios.error!),
            aoTentarDeNovo: () =>
                ref.invalidate(comentariosProvider(widget.alvo)),
          ),
        ],
      );
    } else if (pagina == null) {
      corpo = ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Espacos.xl),
        children: const [Center(child: CircularProgressIndicator())],
      );
    } else if (pagina.itens.isEmpty) {
      corpo = ListView(
        shrinkWrap: true,
        children: const [
          EstadoVazio(
            icone: Symbols.chat_bubble,
            titulo: 'Ninguém comentou ainda',
            texto: 'Escreva o primeiro comentário.',
          ),
        ],
      );
    } else {
      final agora = ref.watch(relogioProvider)();
      corpo = ListView(
        controller: _rolagem,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: Espacos.margemDaTela,
          vertical: Espacos.sm,
        ),
        children: [
          for (final c in pagina.itens)
            _LinhaDeComentario(
              comentario: c,
              agora: agora,
              aoApagar: () => _apagar(c),
            ),
          if (pagina.proximo != null)
            TextButton(
              onPressed: _carregandoMais ? null : _carregarMais,
              child: _carregandoMais
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Carregar mais'),
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Espacos.margemDaTela,
            ),
            child: Text('Comentários ($total)', style: tipografia.tituloMedio),
          ),
          Flexible(child: corpo),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacos.margemDaTela,
                Espacos.sm,
                Espacos.margemDaTela,
                0,
              ),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _erro!,
                  style: tipografia.corpoPequeno.copyWith(color: cores.erro),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Espacos.margemDaTela,
              Espacos.sm,
              Espacos.sm,
              Espacos.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _texto,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) => null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escreva um comentário',
                    ),
                    onChanged: (_) => setState(() => _erro = null),
                  ),
                ),
                IconButton.filled(
                  onPressed: podeEnviar ? _enviar : null,
                  tooltip: 'Enviar',
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Symbols.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaDeComentario extends StatelessWidget {
  const _LinhaDeComentario({
    required this.comentario,
    required this.agora,
    required this.aoApagar,
  });

  final Comentario comentario;
  final DateTime agora;
  final VoidCallback aoApagar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacos.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(
            nome: comentario.autor.nome,
            fotoUrl: comentario.autor.fotoUrl,
            tamanho: 32,
          ),
          const SizedBox(width: Espacos.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: comentario.autor.primeiroNome,
                        style: tipografia.etiquetaMedia.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' · ${haQuantoTempo(comentario.criadoEm, agora)}',
                        style: tipografia.corpoPequeno.copyWith(
                          color: cores.sobreSuperficieVariante,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(comentario.texto, style: tipografia.corpoMedio),
              ],
            ),
          ),
          if (comentario.meu)
            IconButton(
              onPressed: aoApagar,
              tooltip: 'Apagar',
              icon: const Icon(Symbols.delete),
            ),
        ],
      ),
    );
  }
}
