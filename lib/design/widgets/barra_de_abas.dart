import 'package:flutter/material.dart';

import '../cores.dart';
import '../medidas.dart';
import '../tipografia.dart';

class AbaDaBarra {
  const AbaDaBarra({required this.rotulo, required this.icone});

  final String rotulo;
  final IconData icone;
}

/// Barra inferior do Stitch: quatro abas de 80px, ativa em terracota e negrito.
class BarraDeAbas extends StatelessWidget {
  const BarraDeAbas({
    super.key,
    required this.abas,
    required this.indiceAtivo,
    required this.aoSelecionar,
  });

  final List<AbaDaBarra> abas;
  final int indiceAtivo;
  final ValueChanged<int> aoSelecionar;

  static const altura = 80.0;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      decoration: BoxDecoration(
        color: cores.superficie,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2B231E),
            offset: Offset(0, -2),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: altura,
          child: Row(
            children: [
              for (final (i, aba) in abas.indexed)
                Expanded(
                  child: _Aba(
                    aba: aba,
                    ativa: i == indiceAtivo,
                    aoTocar: () => aoSelecionar(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aba extends StatelessWidget {
  const _Aba({required this.aba, required this.ativa, required this.aoTocar});

  final AbaDaBarra aba;
  final bool ativa;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final cor = ativa ? cores.primaria : cores.sobreSuperficieVariante;
    return Semantics(
      button: true,
      selected: ativa,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(Raios.padrao),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(aba.icone, size: 24, color: cor, weight: ativa ? 600 : 400),
            const SizedBox(height: Espacos.xs),
            Text(
              aba.rotulo,
              style: tipografia.etiquetaPequena.copyWith(
                color: cor,
                fontWeight: ativa ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
