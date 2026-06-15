import '../app_platform.dart';
import '../constants.dart';

/// URLs de retorno OAuth — cadastre todas no Supabase (Authentication → URL Configuration).
class OAuthConfig {
  static const webRedirect = webAppUrl;

  /// Deep link padrão do supabase_flutter (preferido no fallback OAuth).
  static const appRedirect = 'io.supabase.flutter://callback';

  /// Esquema alternativo (mantido no AndroidManifest).
  static const legacyAppRedirect = 'com.smbijj.ct_sm_bjj://login-callback';

  /// Web Client ID do Google Cloud (OAuth tipo Web) — mesmo do Supabase → Providers → Google.
  static String get googleWebClientId => googleWebClientIdEnv;

  static String get redirectUrl => isWebApp ? webRedirect : appRedirect;
}
