import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../app/dependencias.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import '../turmas/codigo_de_convite.dart';
import 'codigo_de_amigo.dart';
import 'codigo_em_destaque.dart';
import 'conexoes.dart';

/// O código de um amigo, digitado ou colado com a mensagem inteira, e o meu para mandar. O código
/// que a API recusa vira erro no campo, e o texto fica.
class TelaDeConectarAmigo extends ConsumerStatefulWidget {
  const TelaDeConectarAmigo({super.key});

  @override
  ConsumerState<TelaDeConectarAmigo> createState() =>
      _TelaDeConectarAmigoState();
}

class _TelaDeConectarAmigoState extends ConsumerState<TelaDeConectarAmigo> {
  final _codigo = TextEditingController();
  String? _erro;
  // com a chamada no ar, o 2º toque chamaria a API de novo
  bool _conectando = false;
  bool _gerando = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  bool get _podeConectar => codigoCompleto(_codigo.text) && !_conectando;

  Future<void> _conectar() async {
    // antes do await: com a tela fechada no meio, a conexão ainda entra na lista e o aviso ainda
    // sai, pelo mensageiro da raiz
    final conexoes = ref.read(conexoesProvider.notifier);
    final mensageiro = ScaffoldMessenger.of(context);
    setState(() {
      _conectando = true;
      _erro = null;
    });
    try {
      final (:pessoa, :nova) = await conexoes.conectar(_codigo.text);
      if (mounted) context.pop();
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nova
                  ? 'Agora você e ${pessoa.primeiroNome} estão conectados.'
                  : 'Vocês já estavam conectados.',
            ),
          ),
        );
    } on ErroDaApi catch (e) {
      if (!mounted) return;
      if (e.codigoInvalido) {
        setState(() => _erro = e.mensagem);
      } else {
        mostrarAviso(context, e.mensagem);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _conectando = false);
    }
  }

  Future<void> _copiar(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (mounted) mostrarAviso(context, 'Código copiado');
  }

  Future<void> _gerarNovo() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Gerar um código novo?'),
        content: const Text(
          'O código atual para de funcionar. Quem já é seu amigo continua conectado.',
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
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    final perfil = ref.read(perfilAtualProvider.notifier);
    setState(() => _gerando = true);
    try {
      await perfil.regenerarCodigo();
      if (mounted) mostrarAviso(context, 'Novo código gerado');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipografia = Tipografia.de(context);
    final eu = ref.watch(perfilAtualProvider).value;
    return Scaffold(
      appBar: const Cabecalho(titulo: 'Conectar amigo'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacos.margemDaTela,
          Espacos.md,
          Espacos.margemDaTela,
          Espacos.xl,
        ),
        children: [
          TextField(
            controller: _codigo,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FormatadorDeCodigo()],
            style: tipografia.tituloPequeno.copyWith(letterSpacing: 3),
            decoration: InputDecoration(
              labelText: 'Código do amigo',
              errorText: _erro,
            ),
            onChanged: (_) => setState(() => _erro = null),
          ),
          const SizedBox(height: Espacos.lg),
          FilledButton(
            onPressed: _podeConectar ? _conectar : null,
            child: _conectando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Conectar'),
          ),
          if (eu != null) ...[
            const SizedBox(height: Espacos.xl),
            _CartaoDoMeuCodigo(
              codigo: eu.codigoDeAmigo,
              gerando: _gerando,
              aoCopiar: () => _copiar(eu.codigoDeAmigo),
              aoCompartilhar: () => ref
                  .read(compartilhadorProvider)
                  .compartilhar(textoDoCodigoDeAmigo(eu.codigoDeAmigo)),
              aoGerarNovo: _gerarNovo,
            ),
          ],
        ],
      ),
    );
  }
}

class _CartaoDoMeuCodigo extends StatelessWidget {
  const _CartaoDoMeuCodigo({
    required this.codigo,
    required this.gerando,
    required this.aoCopiar,
    required this.aoCompartilhar,
    required this.aoGerarNovo,
  });

  final String codigo;
  final bool gerando;
  final VoidCallback aoCopiar;
  final VoidCallback aoCompartilhar;
  final VoidCallback aoGerarNovo;

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
      padding: const EdgeInsets.all(Espacos.cartao),
      // em coluna: o tema dá largura mínima infinita aos botões cheios, e numa Row eles estourariam
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seu código',
            style: tipografia.etiquetaMedia.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          const SizedBox(height: Espacos.xs),
          CodigoEmDestaque(codigo),
          const SizedBox(height: Espacos.md),
          OutlinedButton.icon(
            onPressed: aoCopiar,
            icon: const Icon(Symbols.content_copy),
            label: const Text('Copiar'),
          ),
          const SizedBox(height: Espacos.sm),
          FilledButton.icon(
            onPressed: aoCompartilhar,
            icon: const Icon(Symbols.share),
            label: const Text('Compartilhar'),
          ),
          TextButton(
            onPressed: gerando ? null : aoGerarNovo,
            child: const Text('Gerar código novo'),
          ),
        ],
      ),
    );
  }
}
