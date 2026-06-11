import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../utils/image_utils.dart';

/// Imagem de produto com fallback para YouTube e placeholder.
class ProdutoImagem extends StatelessWidget {
  final String? fotoUrl;
  final String? youtubeThumb;
  final bool priorizarVideo;
  final BoxFit fit;

  const ProdutoImagem({
    super.key,
    this.fotoUrl,
    this.youtubeThumb,
    this.priorizarVideo = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (priorizarVideo && youtubeThumb != null) {
      return _youtubeThumbWidget(youtubeThumb!);
    }

    final path = fotoUrl?.isNotEmpty == true ? fotoUrl : null;
    if (path != null && Produto.youtubeVideoIdFromUrl(path) != null) {
      final thumb =
          'https://img.youtube.com/vi/${Produto.youtubeVideoIdFromUrl(path)}/mqdefault.jpg';
      return _youtubeThumbWidget(thumb);
    }

    if (path != null) {
      final remote = path.startsWith('http://') || path.startsWith('https://');
      if (remote) {
        return Container(
          color: Colors.grey.shade100,
          width: double.infinity,
          height: double.infinity,
          child: Image.network(
            path,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _fallbackYoutube(youtubeThumb),
          ),
        );
      }
      return Container(
        color: Colors.grey.shade100,
        width: double.infinity,
        height: double.infinity,
        child: imageWidgetFromPath(
          path,
          fit: fit,
          errorWidget: _fallbackYoutube(youtubeThumb),
        ),
      );
    }

    return _fallbackYoutube(youtubeThumb);
  }

  Widget _youtubeThumbWidget(String thumb) => Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.grey.shade100,
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              thumb,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const ProdutoImagemPlaceholder(),
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle_filled, color: Colors.white, size: 40),
          ),
        ],
      );

  Widget _fallbackYoutube(String? thumb) {
    if (thumb != null) return _youtubeThumbWidget(thumb);
    return const ProdutoImagemPlaceholder();
  }
}

class ProdutoImagemPlaceholder extends StatelessWidget {
  const ProdutoImagemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text('Sem foto', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      );
}
