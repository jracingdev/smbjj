import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../supabase_service.dart';

class DriveBackup {
  static const _fileName = 'ct_sm_bjj_backup.json';

  Future<bool> exportar() async {
    try {
      // Exporta todas as tabelas do Supabase
      final tables = ['alunos', 'mensalidades', 'produtos', 'produto_variantes', 'avisos', 'eventos'];
      final Map<String, dynamic> data = {
        'app': 'ct_sm_bjj',
        'version': 3,
        'exported_at': DateTime.now().toIso8601String(),
      };
      for (final table in tables) {
        data[table] = await supabase.from(table).select();
      }

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(json, encoding: utf8);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: _fileName)],
        subject: 'Backup CT SM BJJ — ${DateTime.now().toIso8601String().substring(0, 10)}',
        text: 'Backup do app CT SM BJJ. Salve este arquivo em local seguro.',
      );
      return result.status != ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }

  Future<BackupRestoreResult> importar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Selecione o arquivo de backup CT SM BJJ',
      );
      if (result == null || result.files.isEmpty) return BackupRestoreResult.cancelado;
      final path = result.files.single.path;
      if (path == null) return BackupRestoreResult.erro;

      final content = await File(path).readAsString(encoding: utf8);
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data['app'] != 'ct_sm_bjj') return BackupRestoreResult.arquivoInvalido;

      // Restaura no Supabase
      final tables = ['avisos', 'eventos', 'produto_variantes', 'produtos', 'mensalidades', 'alunos'];
      for (final table in tables) {
        final rows = data[table] as List<dynamic>? ?? [];
        if (rows.isEmpty) continue;
        await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000');
        await supabase.from(table).insert(rows.map((r) => Map<String, dynamic>.from(r)).toList());
      }
      return BackupRestoreResult.sucesso;
    } catch (_) {
      return BackupRestoreResult.erro;
    }
  }
}

enum BackupRestoreResult { sucesso, cancelado, erro, arquivoInvalido }
