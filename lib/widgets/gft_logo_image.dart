import 'package:flutter/material.dart';

/// Logo Grappling Fight Team — asset em assets/images/gft_logo.png
class GftLogoImage extends StatelessWidget {
  final double height;
  const GftLogoImage({super.key, this.height = 88});

  static const assetPath = 'assets/images/gft_logo.png';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          assert(() {
            debugPrint('Falha ao carregar $assetPath: $error');
            return true;
          }());
          return SizedBox(
            height: height,
            child: Icon(Icons.broken_image_outlined, size: height * 0.45, color: Colors.grey.shade400),
          );
        },
      ),
    );
  }
}
