import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../cores.dart';
import '../medidas.dart';
import '../tipografia.dart';

/// Foto redonda com moldura branca de 4px e sombra quente, como a polaroid do Stitch. Sem foto,
/// ou se ela falhar, mostra as iniciais sobre o terracota claro.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.nome,
    this.fotoUrl,
    this.tamanho = 48,
    this.inclinado = false,
  });

  final String nome;
  final String? fotoUrl;
  final double tamanho;
  final bool inclinado;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final miolo = tamanho - 8;
    final iniciais = _Iniciais(nome: nome, tamanho: miolo);
    final url = fotoUrl;
    return Transform.rotate(
      angle: inclinado ? -2 * math.pi / 180 : 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cores.superficieMaisBaixa,
          boxShadow: Sombras.nivel2,
        ),
        child: ClipOval(
          child: SizedBox(
            width: miolo,
            height: miolo,
            child: url == null
                ? iniciais
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => iniciais,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Iniciais extends StatelessWidget {
  const _Iniciais({required this.nome, required this.tamanho});

  final String nome;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Container(
      color: cores.primariaFixa,
      alignment: Alignment.center,
      child: Text(
        iniciaisDe(nome),
        style: tipografia.tituloPequeno.copyWith(
          color: cores.sobrePrimariaFixaVariante,
          fontSize: tamanho * 0.36,
          height: 1,
        ),
      ),
    );
  }
}

/// Primeira letra do primeiro e do último nome, em maiúsculas. `?` para nome vazio.
String iniciaisDe(String nome) {
  final partes = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.isEmpty) return '?';
  final primeira = String.fromCharCode(partes.first.runes.first);
  final ultima = partes.length > 1
      ? String.fromCharCode(partes.last.runes.first)
      : '';
  return (primeira + ultima).toUpperCase();
}
