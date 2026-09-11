import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A marca: duas meias-luas que se encaixam, sobre o terracota claro do logo original.
class Marca extends StatelessWidget {
  const Marca({super.key, this.tamanho = 32});

  final double tamanho;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ConnActions',
    image: true,
    child: CustomPaint(
      size: Size.square(tamanho),
      painter: const _PintorDaMarca(),
    ),
  );
}

class _PintorDaMarca extends CustomPainter {
  const _PintorDaMarca();

  @override
  void paint(Canvas canvas, Size size) {
    final e = size.width / 100; // o SVG é 100×100; tudo escala por aqui

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(28 * e)),
      Paint()..color = const Color(0xFFD85A38),
    );

    final arcoBranco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * e
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final arcoAmarelo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * e
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFCD34D);

    // Ângulos no sentido do relógio a partir de 3h, como o Canvas mede: o arco branco vai da
    // esquerda pelo topo até embaixo; o amarelo, da direita por baixo até o topo.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(42 * e, 42 * e), radius: 12 * e),
      math.pi,
      3 * math.pi / 2,
      false,
      arcoBranco,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(58 * e, 58 * e), radius: 12 * e),
      0,
      3 * math.pi / 2,
      false,
      arcoAmarelo,
    );

    canvas.drawCircle(
      Offset(50 * e, 50 * e),
      5 * e,
      Paint()..color = Colors.white,
    );

    final x = Paint()
      ..color = const Color(0xFFFEF08A)
      ..strokeWidth = 3 * e
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(68 * e, 32 * e), Offset(72 * e, 36 * e), x);
    canvas.drawLine(Offset(72 * e, 32 * e), Offset(68 * e, 36 * e), x);

    canvas.drawCircle(
      Offset(32 * e, 68 * e),
      3 * e,
      Paint()..color = const Color(0xFFFED7AA),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
