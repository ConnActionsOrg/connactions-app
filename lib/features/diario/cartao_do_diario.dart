import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/atividade.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/etiqueta.dart';
import '../atividades/foto_para_ver.dart';
import '../atividades/visualizador_de_fotos.dart';

/// Uma encerrada no Diário: título, formato em sálvia (concluído), quem propôs e quando, a
/// descrição como citação e a faixa de miniaturas.
class CartaoDoDiario extends StatelessWidget {
  const CartaoDoDiario({
    super.key,
    required this.atividade,
    required this.agora,
  });

  final Atividade atividade;
  final DateTime agora;

  static final _formatoDaData = DateFormat("d 'de' MMMM", 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final encerradaEm = atividade.encerradaEm ?? atividade.lancadaEm;
    final fotos = atividade.registros;
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
            'Proposta por ${atividade.proponente.primeiroNome} · ${_formatoDaData.format(encerradaEm.toLocal())}',
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
          if (atividade.descricao.isNotEmpty) ...[
            const SizedBox(height: Espacos.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Espacos.md),
              decoration: BoxDecoration(
                color: cores.superficieContainer,
                borderRadius: BorderRadius.circular(Raios.padrao),
              ),
              child: Text(
                atividade.descricao,
                style: tipografia.corpoMedio.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: Espacos.md),
          if (fotos.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (_, _) => const SizedBox(width: Espacos.sm),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => mostrarVisualizadorDeFotos(
                    context,
                    fotos: [for (final r in fotos) FotoParaVer.doRegistro(r)],
                    indiceInicial: i,
                    agora: agora,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Raios.pequeno),
                    child: Image.network(
                      fotos[i].miniaturaUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 96,
                        height: 96,
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
              ),
            ),
          if (fotos.isNotEmpty) const SizedBox(height: Espacos.sm),
          Text(
            switch (fotos.length) {
              0 => 'Sem fotos',
              1 => '1 foto',
              final n => '$n fotos',
            },
            style: tipografia.corpoPequeno.copyWith(
              color: cores.sobreSuperficieVariante,
            ),
          ),
        ],
      ),
    );
  }
}
