import 'package:flutter/material.dart';

/// Título brush “BLACK BELT / LEGACY SM BJJ” (asset fiel à arte de referência).
class BlackBeltLegacyTitle extends StatelessWidget {
  final double maxHeight;

  const BlackBeltLegacyTitle({super.key, this.maxHeight = 56});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/black_belt_legacy_title.png',
      height: maxHeight,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
      semanticLabel: 'BLACK BELT LEGACY SM BJJ',
    );
  }
}
