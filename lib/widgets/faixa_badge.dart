import 'package:flutter/material.dart';
import '../utils/bjj_utils.dart';

class FaixaBadge extends StatelessWidget {
  final String faixa;
  final int grau;

  const FaixaBadge({super.key, required this.faixa, this.grau = 0});

  @override
  Widget build(BuildContext context) {
    final bg = getFaixaColor(faixa);
    final textColor = getFaixaTextColor(faixa);
    final border = faixa == 'branca' ? Colors.grey.shade400 : bg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            faixa[0].toUpperCase() + faixa.substring(1),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
          if (grau > 0) ...[
            const SizedBox(width: 4),
            Text(
              '●' * grau,
              style: TextStyle(fontSize: 8, color: textColor.withOpacity(0.8)),
            ),
          ],
        ],
      ),
    );
  }
}
