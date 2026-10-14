import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/capa_do_diario.dart';
import '../../api/modelos/turma.dart';
import '../../app/dependencias.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import 'diario.dart';
import 'paleta.dart';

Future<void> mostrarFolhaDePersonalizar(
  BuildContext context, {
  required Turma turma,
  required CapaDoDiario capa,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  builder: (_) => FolhaDePersonalizar(turma: turma, capa: capa),
);

/// Título, frase, paleta e sticker do Diário. Qualquer membro personaliza. Lê a capa uma vez, ao
/// abrir: o que a pessoa digita não some com uma recarga do Diário por baixo.
class FolhaDePersonalizar extends ConsumerStatefulWidget {
  const FolhaDePersonalizar({
    super.key,
    required this.turma,
    required this.capa,
  });

  final Turma turma;
  final CapaDoDiario capa;

  @override
  ConsumerState<FolhaDePersonalizar> createState() =>
      _FolhaDePersonalizarState();
}

class _FolhaDePersonalizarState extends ConsumerState<FolhaDePersonalizar> {
  late final _titulo = TextEditingController(text: widget.capa.titulo ?? '');
  late final _frase = TextEditingController(text: widget.capa.frase ?? '');
  late PaletaDoDiario _paleta = widget.capa.paleta;
  late StickerDoDiario _sticker = widget.capa.sticker;
  var _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _frase.dispose();
    super.dispose();
  }

  /// Só o que difere do que está gravado vai à API; texto vazio volta ao padrão.
  AlteracoesDaCapa _alteracoes() {
    String? mudou(String digitado, String? gravado) {
      final novo = digitado.trim();
      return novo == (gravado ?? '') ? null : novo;
    }

    return AlteracoesDaCapa(
      titulo: mudou(_titulo.text, widget.capa.titulo),
      frase: mudou(_frase.text, widget.capa.frase),
      paleta: _paleta == widget.capa.paleta ? null : _paleta,
      sticker: _sticker == widget.capa.sticker ? null : _sticker,
    );
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });
    // a folha pode ser dispensada com o PATCH em voo: o que o servidor aceitou tem de chegar ao
    // Diário mesmo assim, e depois do await esta folha já não tem `ref` para ler
    final diario = ref.read(diarioProvider(widget.turma.id).notifier);
    try {
      final nova = await ref
          .read(apiProvider)
          .personalizarDiario(widget.turma.id, _alteracoes());
      diario.trocarCapa(nova);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // dentro da folha: o SnackBar nasce no Scaffold de baixo e ficaria atrás dela
      if (mounted) setState(() => _erro = mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final pode = !_salvando && !_alteracoes().vazia;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Espacos.margemDaTela,
        0,
        Espacos.margemDaTela,
        Espacos.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personalizar o diário', style: tipografia.tituloMedio),
          const SizedBox(height: Espacos.md),
          TextField(
            controller: _titulo,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Título',
              hintText: widget.capa.tituloPara(widget.turma),
            ),
            onChanged: (_) => setState(() => _erro = null),
          ),
          const SizedBox(height: Espacos.sm),
          TextField(
            controller: _frase,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Frase da capa',
              hintText: 'Uma frase que resuma a turma',
            ),
            onChanged: (_) => setState(() => _erro = null),
          ),
          const SizedBox(height: Espacos.md),
          Text('Cor', style: tipografia.etiquetaGrande),
          const SizedBox(height: Espacos.sm),
          Wrap(
            spacing: Espacos.md,
            runSpacing: Espacos.sm,
            children: [
              for (final p in PaletaDoDiario.values)
                _Amostra(
                  paleta: p,
                  selecionada: p == _paleta,
                  aoTocar: () => setState(() => _paleta = p),
                ),
            ],
          ),
          const SizedBox(height: Espacos.md),
          Text('Sticker', style: tipografia.etiquetaGrande),
          const SizedBox(height: Espacos.sm),
          Wrap(
            spacing: Espacos.sm,
            runSpacing: Espacos.sm,
            children: [
              for (final s in StickerDoDiario.values)
                _BotaoDeSticker(
                  sticker: s,
                  selecionado: s == _sticker,
                  aoTocar: () => setState(() => _sticker = s),
                ),
            ],
          ),
          const SizedBox(height: Espacos.lg),
          if (_erro != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _erro!,
                style: tipografia.corpoPequeno.copyWith(color: cores.erro),
              ),
            ),
            const SizedBox(height: Espacos.sm),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: pode ? _salvar : null,
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Um círculo com o fundo da capa da paleta; a escolhida ganha o anel e o visto.
class _Amostra extends StatelessWidget {
  const _Amostra({
    required this.paleta,
    required this.selecionada,
    required this.aoTocar,
  });

  final PaletaDoDiario paleta;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final pintura = coresDaPaleta(paleta, cores);
    return Tooltip(
      message: 'Paleta ${paleta.rotulo}',
      child: Semantics(
        button: true,
        selected: selecionada,
        label: 'Paleta ${paleta.rotulo}',
        excludeSemantics: true,
        child: InkResponse(
          onTap: aoTocar,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pintura.capa,
              border: Border.all(
                width: selecionada ? 3 : 1,
                color: selecionada
                    ? cores.sobreSuperficie
                    : cores.contornoVariante,
              ),
            ),
            child: selecionada
                ? Icon(Symbols.check, color: pintura.textoDaCapa, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}

class _BotaoDeSticker extends StatelessWidget {
  const _BotaoDeSticker({
    required this.sticker,
    required this.selecionado,
    required this.aoTocar,
  });

  final StickerDoDiario sticker;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Tooltip(
      message: 'Sticker ${sticker.rotulo}',
      child: Semantics(
        button: true,
        selected: selecionado,
        label: 'Sticker ${sticker.rotulo}',
        excludeSemantics: true,
        child: InkResponse(
          onTap: aoTocar,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Raios.padrao),
              color: selecionado
                  ? cores.superficieMaisBaixa
                  : cores.superficieContainer,
              border: Border.all(
                width: selecionado ? 3 : 1,
                color: selecionado
                    ? cores.sobreSuperficie
                    : cores.contornoVariante,
              ),
            ),
            child: Text(sticker.glifo, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}
