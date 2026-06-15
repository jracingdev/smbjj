import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_version.dart';
import '../models/produto.dart';
import 'produto_imagem.dart';

/// Área de imagem com toque confiável para ampliar (grid, bottom sheet, loja pública).
class ProdutoImagemComZoom extends StatelessWidget {
  final Produto produto;
  final BoxFit fit;
  final EdgeInsets padding;
  /// Contexto estável para abrir zoom (ex.: tela pai, fora do bottom sheet).
  final BuildContext? navigatorContext;

  const ProdutoImagemComZoom({
    super.key,
    required this.produto,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.navigatorContext,
  });

  void _abrir(BuildContext context) {
    HapticFeedback.lightImpact();
    final ctx = navigatorContext ?? context;
    ProdutoImagemAmpliada.mostrarProduto(ctx, produto);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerUp: (_) => _abrir(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: ProdutoImagem(
              fotoUrl: produto.fotoUrl,
              youtubeThumb: produto.youtubeThumbnail,
              priorizarVideo: produto.temVideoYouTube,
              fit: fit,
              padding: padding,
            ),
          ),
          const Positioned(
            right: 6,
            bottom: 6,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x8C000000),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.zoom_in, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
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
    HapticFeedback.mediumImpact();
    final nav = Navigator.of(context, rootNavigator: true);
    return nav.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _ProdutoZoomPage(
          titulo: titulo,
          fotoUrl: fotoUrl,
          youtubeThumb: youtubeThumb,
          priorizarVideo: priorizarVideo,
        ),
      ),
    );
  }

  static Future<void> mostrarProduto(BuildContext context, Produto p) {
    return mostrar(
      context,
      titulo: p.nome,
      fotoUrl: p.fotoUrl,
      youtubeThumb: p.youtubeThumbnail,
      priorizarVideo: p.temVideoYouTube,
    );
  }
}

class _ProdutoZoomPage extends StatelessWidget {
  final String titulo;
  final String? fotoUrl;
  final String? youtubeThumb;
  final bool priorizarVideo;

  const _ProdutoZoomPage({
    required this.titulo,
    this.fotoUrl,
    this.youtubeThumb,
    this.priorizarVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              AppVersion.label,
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
