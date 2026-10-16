import 'package:flutter/material.dart';

import '../../design/tipografia.dart';

/// O meu código de amigo em letra grande, para ler e ditar. Com a fonte do Android no máximo, ele
/// encolhe em vez de quebrar: partido em duas linhas, não dá para ditar.
class CodigoEmDestaque extends StatelessWidget {
  const CodigoEmDestaque(this.codigo, {super.key, this.cor});

  final String codigo;
  final Color? cor;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(
      codigo,
      style: Tipografia.de(
        context,
      ).tituloGrande.copyWith(color: cor, letterSpacing: 4),
    ),
  );
}
