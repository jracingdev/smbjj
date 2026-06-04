import 'package:flutter/material.dart';

import '../utils/bjj_utils.dart';

class FaixaIlustrada extends StatelessWidget {
  final String faixa;
  final int grau;
  final double largura;
  final bool mostrarLegenda;
  final Color? corLegenda;

  const FaixaIlustrada({
    super.key,
    required this.faixa,
    this.grau = 0,
    this.largura = 200,
    this.mostrarLegenda = true,
    this.corLegenda,
  });

  @override
  Widget build(BuildContext context) {
    final nome = faixa.isEmpty ? '—' : faixa[0].toUpperCase() + faixa.substring(1);
    final legenda = grau > 0 ? '$nome · $grau° grau' : nome;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(largura, 36),
          painter: _FaixaPainter(
            cor: getFaixaColor(faixa),
            borda: faixa == 'branca' ? Colors.grey.shade500 : getFaixaColor(faixa).withValues(alpha: 0.6),
            grau: grau.clamp(0, 4),
          ),
        ),
        if (mostrarLegenda) ...[
          const SizedBox(height: 6),
          Text(
            legenda,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: corLegenda ?? Colors.black87,
            ),
          ),
        ],
      ],
    );
  }
}

class _FaixaPainter extends CustomPainter {
  final Color cor;
  final Color borda;
  final int grau;

  _FaixaPainter({required this.cor, required this.borda, required this.grau});

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.6),
      const Radius.circular(4),
    );
    final fill = Paint()..color = cor;
    final stroke = Paint()
      ..color = borda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(r, fill);
    canvas.drawRRect(r, stroke);

    if (grau > 0) {
      final faixaH = size.height * 0.6;
      final top = size.height * 0.2;
      final centroY = top + faixaH / 2;
      const barraW = 6.0;
      const espaco = 10.0;
      final totalW = grau * barraW + (grau - 1) * espaco;
      var x = (size.width - totalW) / 2;
      final barra = Paint()..color = Colors.black87;
      for (var i = 0; i < grau; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x + barraW / 2, centroY), width: barraW, height: faixaH * 0.85),
            const Radius.circular(1),
          ),
          barra,
        );
        x += barraW + espaco;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FaixaPainter old) =>
      old.cor != cor || old.grau != grau || old.borda != borda;
}

bool alunoExibeGraduacao(String? faixa, int grau, bool cadastroValidado) {
  if (!cadastroValidado) return false;
  return true;
}
