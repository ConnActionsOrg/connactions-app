import 'package:flutter/material.dart';

import '../../design/widgets/marca.dart';

/// Só a marca, sem indicador girando: o redirect troca a tela assim que a sessão é conhecida, e
/// animação infinita aqui penduraria o pumpAndSettle dos testes.
class TelaDeAbertura extends StatelessWidget {
  const TelaDeAbertura({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Marca(tamanho: 96)));
}
