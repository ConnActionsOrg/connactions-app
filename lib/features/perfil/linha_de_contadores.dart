import 'package:flutter/material.dart';

import '../../api/modelos/perfil_de_pessoa.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';

/// "4 Turmas", "23 Atividades" e "18 Conexões", lado a lado. O de atividades some quando a pessoa
/// as deixou só para si; carregando, os números são "–".
class LinhaDeContadores extends StatelessWidget {
  const LinhaDeContadores({super.key, required PerfilDePessoa this.perfil});

  const LinhaDeContadores.carregando({super.key}) : perfil = null;

  final PerfilDePessoa? perfil;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final p = perfil;
    final contadores = [
      _Contador(
        numero: p?.turmas,
        singular: 'Turma',
        plural: 'Turmas',
        cor: cores.primaria,
      ),
      if (p == null || p.atividades != null)
        _Contador(
          numero: p?.atividades,
          singular: 'Atividade',
          plural: 'Atividades',
          cor: cores.secundaria,
        ),
      _Contador(
        numero: p?.conexoes,
        singular: 'Conexão',
        plural: 'Conexões',
        cor: cores.terciaria,
      ),
    ];
    return Row(
      children: [
        for (final (i, contador) in contadores.indexed) ...[
          if (i > 0) const SizedBox(width: Espacos.sm),
          Expanded(child: contador),
        ],
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.numero,
    required this.singular,
    required this.plural,
    required this.cor,
  });

  final int? numero;
  final String singular;
  final String plural;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final n = numero;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Espacos.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: cores.superficieMaisBaixa,
          borderRadius: BorderRadius.circular(Raios.padrao),
          boxShadow: Sombras.nivel1,
        ),
        // com a fonte grande do Android, o número e o rótulo encolhem para caber, em vez de partir
        // no meio da palavra ou sair cortados
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                n == null ? '–' : '$n',
                style: tipografia.tituloMedio.copyWith(color: cor),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                n == 1 ? singular : plural,
                style: tipografia.etiquetaMedia.copyWith(
                  color: cores.sobreSuperficieVariante,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
