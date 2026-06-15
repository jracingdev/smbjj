import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'produto_imagem.dart';

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
