import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/foto_para_enviar.dart';
import '../../app/dependencias.dart';
import '../../app/seletor_de_foto.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';
import 'atividade_aberta.dart';
import 'folha_de_origem_da_foto.dart';

/// Folha de origem → seletor do aparelho → esta tela. Cancelar em qualquer ponto não faz nada.
Future<void> abrirNovoRegistro(
  BuildContext context,
  WidgetRef ref, {
  required String turmaId,
}) async {
  final origem = await mostrarFolhaDeOrigemDaFoto(context);
  if (origem == null || !context.mounted) return;
  final foto = await _escolherFoto(context, ref, origem);
  if (foto == null || !context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => TelaDeNovoRegistro(turmaId: turmaId, foto: foto),
    ),
  );
}

/// `null` quando a pessoa cancela e também quando o aparelho não consegue (sem câmera, permissão
/// negada): o plugin lança em vez de devolver null, e aí o motivo vira aviso.
Future<FotoParaEnviar?> _escolherFoto(
  BuildContext context,
  WidgetRef ref,
  OrigemDaFoto origem,
) async {
  try {
    return await ref.read(seletorDeFotoProvider).escolher(origem);
  } catch (e) {
    if (context.mounted) mostrarAviso(context, mensagemDoErro(e));
    return null;
  }
}

/// Prévia da foto escolhida e a legenda. Posta na atividade aberta da turma.
class TelaDeNovoRegistro extends ConsumerStatefulWidget {
  const TelaDeNovoRegistro({
    super.key,
    required this.turmaId,
    required this.foto,
  });

  final String turmaId;
  final FotoParaEnviar foto;

  @override
  ConsumerState<TelaDeNovoRegistro> createState() => _TelaDeNovoRegistroState();
}

class _TelaDeNovoRegistroState extends ConsumerState<TelaDeNovoRegistro> {
  final _legenda = TextEditingController();
  bool _postando = false;

  @override
  void dispose() {
    _legenda.dispose();
    super.dispose();
  }

  Future<void> _postar() async {
    setState(() => _postando = true);
    // capturado antes de navegar: o aviso aparece no Feed, não nesta tela que vai fechar
    final mensageiro = ScaffoldMessenger.of(context);
    final aberta = ref.read(atividadeAbertaProvider(widget.turmaId).notifier);
    try {
      await aberta.registrar(widget.foto, _legenda.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Registro postado!')),
      );
    } on ErroDaApi catch (e) {
      if (!mounted) return;
      if (e.conflito) {
        // o estado mudou embaixo de mim (já postei em outro aparelho, alguém encerrou): recarrega e volta
        ref.invalidate(atividadeAbertaProvider(widget.turmaId));
        Navigator.of(context).pop();
        mensageiro.showSnackBar(SnackBar(content: Text(e.mensagem)));
      } else {
        mostrarAviso(context, e.mensagem);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _postando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Segura a aberta enquanto a tela existe: o registrar espera o carregamento e grava nela, e um
    // provider autoDispose sem ouvinte é descartado no meio da requisição.
    ref.listen(atividadeAbertaProvider(widget.turmaId), (_, _) {});
    final cores = Cores.de(context);
    final altura = MediaQuery.sizeOf(context).height * 0.6;
    return Scaffold(
      appBar: const Cabecalho(titulo: 'Novo registro'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacos.margemDaTela,
          Espacos.md,
          Espacos.margemDaTela,
          Espacos.xl,
        ),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Raios.medio),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: altura),
              child: Image.memory(
                widget.foto.bytes,
                fit: BoxFit.contain,
                // bytes que não decodificam (o dublê dos testes) viram o fundo neutro, não exceção
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: cores.superficieContainer,
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.image,
                    color: cores.sobreSuperficieVariante,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Espacos.lg),
          TextField(
            controller: _legenda,
            maxLength: 200,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Legenda (opcional)',
              hintText: 'Bolo de milho da vovó',
            ),
          ),
          const SizedBox(height: Espacos.xl),
          FilledButton(
            onPressed: _postando ? null : _postar,
            child: _postando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Postar'),
          ),
        ],
      ),
    );
  }
}
