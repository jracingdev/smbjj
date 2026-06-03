import 'package:flutter/material.dart';

bool _isValidUrl(String path) =>
    path.startsWith('http://') ||
    path.startsWith('https://') ||
    path.startsWith('blob:');

/// Web: só URLs válidas funcionam (http/https/blob)
/// Paths locais do Android (/data/user/...) são ignorados
ImageProvider imageProviderFromPath(String path) {
  if (!_isValidUrl(path)) return const AssetImage('assets/images/logo.png');
  return NetworkImage(path);
}

Widget imageWidgetFromPath(String path, {BoxFit fit = BoxFit.cover, Widget? errorWidget}) {
  if (!_isValidUrl(path)) return errorWidget ?? const SizedBox();
  return Image.network(path, fit: fit,
      errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox());
}
