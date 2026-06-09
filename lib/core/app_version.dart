import 'constants.dart';

/// Versão exibida na UI — valores compilados em [constants.dart] / pubspec.yaml.
class AppVersion {
  static String get version => appVersion;
  static String get build => appBuild;
  static String get label => 'v$appVersion (b$appBuild)';
  static String get short => 'v$appVersion';
  static String get packageName => 'com.smbijj.ct_sm_bjj';
}
