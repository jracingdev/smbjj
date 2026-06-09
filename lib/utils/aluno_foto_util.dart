import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../core/storage_service.dart';
import '../core/theme.dart';

/// Escolhe foto (galeria ou câmera), recorta e envia ao bucket `fotos/alunos/`.
Future<String?> escolherEEnviarFotoAluno({
  required BuildContext context,
  required String alunoId,
  String? fotoUrlAtual,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Foto do perfil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tirar foto agora'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final picker = ImagePicker();
  final img = await picker.pickImage(source: source, imageQuality: 90);
  if (img == null) return null;

  Uint8List bytes;
  String ext;
  String? localPath;

  if (!kIsWeb) {
    final cropped = await ImageCropper().cropImage(
      sourcePath: img.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar foto',
          toolbarColor: verdeEscuro,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Recortar foto',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null) return null;
    bytes = await cropped.readAsBytes();
    localPath = cropped.path;
    ext = cropped.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
  } else {
    bytes = await img.readAsBytes();
    localPath = null;
    ext = 'jpg';
    final nome = img.name.toLowerCase();
    if (nome.endsWith('.png')) ext = 'png';
    if (nome.endsWith('.webp')) ext = 'webp';
  }

  final urlRemota = fotoUrlAtual != null &&
          (fotoUrlAtual.startsWith('http://') || fotoUrlAtual.startsWith('https://'))
      ? fotoUrlAtual
      : null;

  return uploadFotoBucket(
    pasta: 'alunos/$alunoId',
    bytes: bytes,
    extension: ext,
    localPath: localPath,
    urlAtual: urlRemota,
  );
}

bool fotoAlunoExibivel(String? url) =>
    url != null &&
    url.isNotEmpty &&
    (url.startsWith('http://') || url.startsWith('https://') || (!kIsWeb && url.isNotEmpty));
