import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

Future<String?> uploadFotoBucket({
  required String localPath,
  required String pasta,
  String? urlAtual,
}) async {
  if (localPath.startsWith('http')) return localPath;

  final file = File(localPath);
  if (!await file.exists()) return urlAtual;

  final ext = _extensao(localPath);
  final storagePath = '$pasta/${DateTime.now().millisecondsSinceEpoch}.$ext';

  try {
    await supabase.storage.from('fotos').upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        upsert: true,
        contentType: _mime(ext),
      ),
    );
    return supabase.storage.from('fotos').getPublicUrl(storagePath);
  } catch (e) {
    debugPrint('uploadFotoBucket: $e');
    return null;
  }
}

String _mime(String ext) {
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}

String _extensao(String path) {
  final p = path.split('.').last.toLowerCase();
  if (p == 'jpg' || p == 'jpeg' || p == 'png' || p == 'webp') return p == 'jpeg' ? 'jpg' : p;
  return 'jpg';
}
