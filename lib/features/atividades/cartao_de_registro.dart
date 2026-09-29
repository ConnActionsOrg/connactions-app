import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/registro.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';
import '../../design/widgets/etiqueta.dart';

/// Miniatura com o autor sobre a foto e a legenda embaixo, como a fileira "Quem já fez" do Stitch.
class CartaoDeRegistro extends StatelessWidget {
  const CartaoDeRegistro({
    super.key,
    required this.registro,
    this.meu = false,
    required this.aoTocar,
  });

  final Registro registro;
  final bool meu;
  final VoidCallback aoTocar;

  static const largura = 160.0;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return SizedBox(
      width: largura,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(Raios.padrao),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Raios.padrao),
                child: Stack(
                  children: [
                    SizedBox(
                      width: largura,
                      height: largura,
                      child: Image.network(
                        registro.miniaturaUrl,
                        fit: BoxFit.cover,
                        // sem rede a miniatura vira um fundo neutro, nunca uma exceção
                        errorBuilder: (_, _, _) => Container(
                          color: cores.superficieContainer,
                          alignment: Alignment.center,
                          child: Icon(
                            Symbols.image,
                            color: cores.sobreSuperficieVariante,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: Espacos.sm,
                      top: Espacos.sm,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                        decoration: BoxDecoration(
                          color: cores.superficieMaisBaixa.withValues(
                            alpha: 0.85,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Avatar(
                              nome: registro.autor.nome,
                              fotoUrl: registro.autor.fotoUrl,
                              tamanho: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              registro.autor.primeiroNome,
                              style: tipografia.etiquetaPequena,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (meu)
                      const Positioned(
                        right: Espacos.sm,
                        top: Espacos.sm,
                        child: Etiqueta(texto: 'Seu', tom: TomDaEtiqueta.ambar),
                      ),
                  ],
                ),
              ),
              if (registro.legenda.isNotEmpty) ...[
                const SizedBox(height: Espacos.sm),
                Text(
                  registro.legenda,
                  style: tipografia.corpoPequeno,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
