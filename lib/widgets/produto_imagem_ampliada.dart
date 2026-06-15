import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'produto_imagem.dart';

/// Área de imagem com overlay de toque confiável (Android / grid / bottom sheet).
class ProdutoImagemComZoom extends StatelessWidget {
  final Produto produto;
  final BoxFit fit;
  final EdgeInsets padding;

  const ProdutoImagemComZoom({
    super.key,
    required this.produto,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
  });

  void _abrir(BuildContext context) {
    ProdutoImagemAmpliada.mostrarProduto(context, produto);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ProdutoImagem(
          fotoUrl: produto.fotoUrl,
          youtubeThumb: produto.youtubeThumbnail,
          priorizarVideo: produto.temVideoYouTube,
          fit: fit,
          padding: padding,
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _abrir(context),
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
            ),
          ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _abrir(context),
              borderRadius: BorderRadius.circular(8),
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.zoom_in, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Abre a foto do produto em tela cheia com zoom (pinch/drag).
class ProdutoImagemAmpliada {
  ProdutoImagemAmpliada._();

  static Future<void> mostrar(
    BuildContext context, {
    required String titulo,
    String? fotoUrl,
    String? youtubeThumb,
    bool priorizarVideo = false,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: ProdutoImagem(
                  fotoUrl: fotoUrl,
                  youtubeThumb: youtubeThumb,
                  priorizarVideo: priorizarVideo,
                  fit: BoxFit.contain,
                  padding: const EdgeInsets.all(24),
                  backgroundColor: Colors.black,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void mostrarProduto(BuildContext context, Produto p) {
    mostrar(
      context,
      titulo: p.nome,
      fotoUrl: p.fotoUrl,
      youtubeThumb: p.youtubeThumbnail,
      priorizarVideo: p.temVideoYouTube,
    );
  }
}
