import 'package:flutter/material.dart';

import '../../api/modelos/atividade.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/etiqueta.dart';
import 'tempo.dart';

/// O cartão branco do Stitch: formato, prazo e visibilidade em etiquetas, título, descrição e a
/// caixa de regras. Serve o Feed (com rodapé para o proponente) e o que mais precisar.
class CartaoDaAtividade extends StatelessWidget {
  const CartaoDaAtividade({
    super.key,
    required this.atividade,
    required this.agora,
    this.rodape,
  });

  final Atividade atividade;
  final DateTime agora;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final prazo = atividade.prazo;
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
          Wrap(
            spacing: Espacos.sm,
            runSpacing: Espacos.sm,
            children: [
              Etiqueta(texto: atividade.formato.rotulo),
              if (prazo == null)
                const Etiqueta(texto: 'Sem pressa', tom: TomDaEtiqueta.ambar)
              else
                Etiqueta(
                  texto: tempoRestante(prazo, agora),
                  tom: atividade.prazoVenceu(agora)
                      ? TomDaEtiqueta.terracota
                      : TomDaEtiqueta.ambar,
                ),
              if (atividade.publica)
                const Etiqueta(texto: 'Pública', tom: TomDaEtiqueta.salvia),
            ],
          ),
          const SizedBox(height: Espacos.md),
          Text(atividade.titulo, style: tipografia.tituloMedio),
          if (atividade.descricao.isNotEmpty) ...[
            const SizedBox(height: Espacos.sm),
            Text(atividade.descricao, style: tipografia.corpoMedio),
          ],
          if (atividade.regras.isNotEmpty) ...[
            const SizedBox(height: Espacos.md),
            CaixaDeRegras(regras: atividade.regras),
          ],
          if (rodape != null) ...[const SizedBox(height: Espacos.md), rodape!],
        ],
      ),
    );
  }
}

/// A caixa das regras em tópicos: o cartão da atividade e o da Comunidade a usam.
class CaixaDeRegras extends StatelessWidget {
  const CaixaDeRegras({super.key, required this.regras});

  final List<String> regras;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espacos.md),
      decoration: BoxDecoration(
        color: cores.superficieContainer,
        borderRadius: BorderRadius.circular(Raios.padrao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final regra in regras)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: tipografia.corpoMedio.copyWith(
                      color: cores.primaria,
                    ),
                  ),
                  Expanded(child: Text(regra, style: tipografia.corpoMedio)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
