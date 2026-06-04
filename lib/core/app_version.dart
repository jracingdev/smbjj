import 'package:package_info_plus/package_info_plus.dart';

/// Versão exibida na UI = mesma do APK (`pubspec.yaml`), não constante manual.
class AppVersion {
  static String version = '—';
  static String build = '—';

  static String get label => 'v$version (b$build)';
  static String get short => 'v$version';

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
    build = info.buildNumber;
  }
}
