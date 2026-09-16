import 'package:flutter/material.dart';

import '../cores.dart';
import '../medidas.dart';
import '../tipografia.dart';
import 'marca.dart';

/// Cabeçalho fixo das telas: marca e nome em terracota. É um AppBar por baixo, então numa tela
/// empilhada a seta de voltar aparece sozinha.
class Cabecalho extends StatelessWidget implements PreferredSizeWidget {
  const Cabecalho({super.key, this.titulo, this.acoes = const []});

  /// Com título, a tela é uma página empilhada: ele entra no lugar da marca, e a seta de voltar
  /// vem sozinha do AppBar.
  final String? titulo;
  final List<Widget> acoes;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: Espacos.margemDaTela,
      shape: const Border(bottom: BorderSide(color: Color(0x0A2B231E))),
      title: titulo == null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Marca(tamanho: 32),
                const SizedBox(width: Espacos.sm),
                Text(
                  'ConnActions',
                  style: tipografia.tituloPequeno.copyWith(
                    color: cores.primaria,
                    letterSpacing: -0.36,
                  ),
                ),
              ],
            )
          : Text(
              titulo!,
              style: tipografia.tituloPequeno,
              overflow: TextOverflow.ellipsis,
            ),
      actions: acoes,
    );
  }
}
