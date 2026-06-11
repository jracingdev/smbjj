import 'package:package_info_plus/package_info_plus.dart';
import 'constants.dart';

/// Versão exibida na UI — lê do APK instalado (package_info) com fallback em constants.
class AppVersion {
  static String _version = appVersion;
  static String _build = appBuild;

  static Future<void> inicializar() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) _version = info.version;
      if (info.buildNumber.isNotEmpty) _build = info.buildNumber;
    } catch (_) {
      _version = appVersion;
      _build = appBuild;
    }
  }

  static String get version => _version;
  static String get build => _build;
  static String get label => 'v$_version (b$_build)';
  static String get short => 'v$_version';
  static String get packageName => 'com.smbijj.ct_sm_bjj';
}
