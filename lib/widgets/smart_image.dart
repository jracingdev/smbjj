import 'dart:io';
import 'package:flutter/material.dart';

/// Exibe imagem de URL (http) ou arquivo local automaticamente
class SmartImage extends StatelessWidget {
  final String? path;
  final double? width, height;
  final BoxFit fit;
  final Widget? placeholder;

  const SmartImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return placeholder ?? _defaultPlaceholder();
    }

    final isNetwork = path!.startsWith('http://') || path!.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        path!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Center(child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            )),
      );
    }

    final file = File(path!);
    if (!file.existsSync()) return placeholder ?? _defaultPlaceholder();

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
    );
  }

  Widget _defaultPlaceholder() => Container(
    width: width,
    height: height,
    color: Colors.grey.shade100,
    child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
  );
}
