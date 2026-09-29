import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/mensagens.dart';
import '../../api/modelos/registro.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/aviso.dart';
import 'tempo.dart';

/// Abre o visualizador por cima de tudo (navigator da raiz): ele carrega a lista, não cabe numa rota.
Future<void> mostrarVisualizadorDeFotos(
  BuildContext context, {
  required List<Registro> registros,
  required int indiceInicial,
  required DateTime agora,
  bool Function(Registro)? podeApagar,
  Future<void> Function(Registro)? aoApagar,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => VisualizadorDeFotos(
      registros: registros,
      indiceInicial: indiceInicial,
      agora: agora,
      podeApagar: podeApagar,
      aoApagar: aoApagar,
    ),
  ),
);

/// Fotos em tela cheia com autor e legenda. "Apagar" só quando `podeApagar` diz sim; apagada a
/// última, fecha.
class VisualizadorDeFotos extends StatefulWidget {
  const VisualizadorDeFotos({
    super.key,
    required this.registros,
    required this.indiceInicial,
    required this.agora,
    this.podeApagar,
    this.aoApagar,
  });

  final List<Registro> registros;
  final int indiceInicial;
  final DateTime agora;
  final bool Function(Registro)? podeApagar;
  final Future<void> Function(Registro)? aoApagar;

  @override
  State<VisualizadorDeFotos> createState() => _VisualizadorDeFotosState();
}

class _VisualizadorDeFotosState extends State<VisualizadorDeFotos> {
  late final List<Registro> _registros = List.of(widget.registros);
  late int _indice = widget.indiceInicial
      .clamp(0, widget.registros.length - 1)
      .toInt();
  late final _paginas = PageController(initialPage: _indice);
  bool _apagando = false;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  Future<void> _apagar() async {
    final registro = _registros[_indice];
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Apagar seu registro?'),
        content: const Text(
          'A foto sai da atividade. Você pode postar outra enquanto ela estiver aberta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _apagando = true);
    try {
      await widget.aoApagar!(registro);
      if (!mounted) return;
      if (_registros.length == 1) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _registros.removeAt(_indice);
        _indice = _indice.clamp(0, _registros.length - 1).toInt();
        _paginas.jumpToPage(_indice);
      });
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _apagando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final atual = _registros[_indice];
    final podeApagar =
        widget.aoApagar != null && (widget.podeApagar?.call(atual) ?? false);
    return Scaffold(
      backgroundColor: cores.superficieInversa,
      appBar: AppBar(
        backgroundColor: cores.superficieInversa,
        foregroundColor: cores.sobreSuperficieInversa,
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_indice + 1} / ${_registros.length}',
          style: tipografia.rotuloTitulo.copyWith(
            color: cores.sobreSuperficieInversa,
          ),
        ),
        actions: [
          if (podeApagar)
            IconButton(
              tooltip: 'Apagar',
              icon: const Icon(Symbols.delete),
              onPressed: _apagando ? null : _apagar,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _paginas,
              itemCount: _registros.length,
              onPageChanged: (i) => setState(() => _indice = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: Image.network(
                    _registros[i].fotoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Symbols.broken_image,
                      size: 64,
                      color: cores.sobreSuperficieInversa,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Espacos.margemDaTela,
              Espacos.md,
              Espacos.margemDaTela,
              Espacos.lg,
            ),
            child: Row(
              children: [
                Avatar(
                  nome: atual.autor.nome,
                  fotoUrl: atual.autor.fotoUrl,
                  tamanho: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atual.autor.nome,
                        style: tipografia.rotuloTitulo.copyWith(
                          color: cores.sobreSuperficieInversa,
                        ),
                      ),
                      Text(
                        atual.legenda.isEmpty
                            ? haQuantoTempo(atual.criadoEm, widget.agora)
                            : '${atual.legenda} · ${haQuantoTempo(atual.criadoEm, widget.agora)}',
                        style: tipografia.corpoPequeno.copyWith(
                          color: cores.sobreSuperficieInversa,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
