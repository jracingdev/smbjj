import 'package:flutter/foundation.dart';

Future<String?> uploadFotoBucket({
  required String localPath,
  required String pasta,
  String? urlAtual,
}) async {
  if (localPath.startsWith('http')) return localPath;
  debugPrint('uploadFotoBucket: upload de arquivo local na web requer URL já hospedada.');
  return urlAtual;
}
