import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../utils/image_utils.dart';

class AlunoAvatar extends StatelessWidget {
  final String? fotoUrl;
  final String nome;
  final double radius;

  const AlunoAvatar({
    super.key,
    required this.fotoUrl,
    required this.nome,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      final img = imageProviderFromPath(fotoUrl!);
      return CircleAvatar(
        radius: radius,
        backgroundImage: img,
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: verdeEscuro,
      child: Text(
        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
