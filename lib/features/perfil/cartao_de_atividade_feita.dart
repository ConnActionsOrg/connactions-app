import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/atividade_feita.dart';
import '../../api/modelos/foto_sem_autor.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/etiqueta.dart';
import '../atividades/foto_para_ver.dart';
import '../atividades/visualizador_de_fotos.dart';

/// Uma atividade feita no perfil: o título, de que turma e quando, o formato e a primeira foto
/// grande, com "+N" quando há mais. Sem reações nem comentários, que são do Diário da turma.
class CartaoDeAtividadeFeita extends StatelessWidget {
  const CartaoDeAtividadeFeita({
    super.key,
    required this.atividade,
    required this.agora,
  });

  final AtividadeFeita atividade;

  /// O relógio do app, que o visualizador pede.
  final DateTime agora;

  static final _formatoDaData = DateFormat("d 'de' MMMM", 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final primeira = atividade.fotos.firstOrNull;
    final data = _formatoDaData.format(atividade.encerradaEm.toLocal());
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(atividade.titulo, style: tipografia.tituloMedio),
              ),
              const SizedBox(width: Espacos.sm),
              Etiqueta(
                texto: atividade.formato.rotulo,
                tom: TomDaEtiqueta.salvia,
              ),
            ],
          ),
          const SizedBox(height: Espacos.xs),
          Text(
            '${atividade.turmaEmoji} ${atividade.turmaNome} · $data',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          if (primeira != null) ...[
            const SizedBox(height: Espacos.md),
            _FotoGrande(fotos: atividade.fotos, agora: agora),
            if (primeira.legenda.isNotEmpty) ...[
              const SizedBox(height: Espacos.sm),
              Text(
                primeira.legenda,
                style: tipografia.corpoMedio.copyWith(
                  fontStyle: FontStyle.italic,
                  color: cores.sobreSuperficieVariante,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// A primeira foto em destaque e o "+N" das outras; o toque abre todas no visualizador, sem autor.
class _FotoGrande extends StatelessWidget {
  const _FotoGrande({required this.fotos, required this.agora});

  final List<FotoSemAutor> fotos;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final mais = fotos.length - 1;
    return Semantics(
      button: true,
      label: fotos.length == 1 ? 'Ver a foto' : 'Ver as ${fotos.length} fotos',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => mostrarVisualizadorDeFotos(
          context,
          fotos: [for (final f in fotos) FotoParaVer.semAutor(f)],
          indiceInicial: 0,
          agora: agora,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Raios.padrao),
          child: SizedBox(
            height: 192,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  fotos.first.fotoUrl,
                  fit: BoxFit.cover,
                  // sem rede a foto vira um fundo neutro, nunca uma exceção
                  errorBuilder: (_, _, _) => Container(
                    color: cores.superficieContainer,
                    alignment: Alignment.center,
                    child: Icon(
                      Symbols.image,
                      color: cores.sobreSuperficieVariante,
                    ),
                  ),
                ),
                if (mais > 0)
                  Positioned(
                    right: Espacos.sm,
                    bottom: Espacos.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: Espacos.xs,
                      ),
                      decoration: BoxDecoration(
                        color: cores.superficieInversa.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+$mais',
                        style: tipografia.etiquetaMedia.copyWith(
                          color: cores.sobreSuperficieInversa,
                        ),
                      ),
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
