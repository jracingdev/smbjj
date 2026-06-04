import 'package:flutter/material.dart';
import '../utils/bjj_utils.dart';

/// Barra visual da faixa com listras de grau (CBJJ).
class FaixaIlustracao extends StatelessWidget {
  final String faixa;
  final int grau;
  final double width;
  final double height;

  const FaixaIlustracao({
    super.key,
    required this.faixa,
    this.grau = 0,
    this.width = 140,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final corFaixa = getFaixaColor(faixa);
    final borda = faixa == 'branca' ? Colors.grey.shade400 : corFaixa.withValues(alpha: 0.6);
    final listras = grau.clamp(0, 4);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: borda, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Container(color: corFaixa),
          ),
          if (listras > 0)
            Expanded(
              flex: 3,
              child: Container(
                color: faixa == 'preta' ? const Color(0xFF1a1a1a) : corFaixa.withValues(alpha: 0.85),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    listras,
                    (_) => Container(
                      width: 3,
                      height: height * 0.55,
                      decoration: BoxDecoration(
                        color: faixa == 'preta' ? Colors.red.shade700 : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FaixaBadge extends StatelessWidget {
  final String faixa;
  final int grau;
  final bool mostrarIlustracao;

  const FaixaBadge({
    super.key,
    required this.faixa,
    this.grau = 0,
    this.mostrarIlustracao = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = getFaixaColor(faixa);
    final textColor = getFaixaTextColor(faixa);
    final border = faixa == 'branca' ? Colors.grey.shade400 : bg;
    final label = faixa[0].toUpperCase() + faixa.substring(1);
    final grauLabel = grau > 0 ? ' · $grau°' : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (mostrarIlustracao) ...[
          FaixaIlustracao(faixa: faixa, grau: grau, width: 120, height: 14),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$label$grauLabel',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ],
    );
  }
}
