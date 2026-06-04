import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

Future<String?> uploadFotoBucket({
  required String pasta,
  String? localPath,
  Uint8List? bytes,
  String extension = 'jpg',
  String? urlAtual,
}) async {
  if (localPath != null &&
      (localPath.startsWith('http://') || localPath.startsWith('https://'))) {
    return localPath;
  }

  final ext = extension == 'jpeg' ? 'jpg' : extension;
  final storagePath = '$pasta/${DateTime.now().millisecondsSinceEpoch}.$ext';

  try {
    if (bytes != null && bytes.isNotEmpty) {
      await supabase.storage.from('fotos').uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: _mime(ext)),
      );
    } else if (localPath != null) {
      final file = File(localPath);
      if (!await file.exists()) return urlAtual;
      await supabase.storage.from('fotos').upload(
        storagePath,
        file,
        fileOptions: FileOptions(upsert: true, contentType: _mime(ext)),
      );
    } else {
      return urlAtual;
    }
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
