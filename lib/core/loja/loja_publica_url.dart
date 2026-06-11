import '../auth/oauth_config.dart';

String urlLojaPublica() {
  final base = Uri.parse(OAuthConfig.webRedirect);
  return base.replace(queryParameters: {'loja': 'publica'}).toString();
}

bool urlEhLojaPublica(Uri uri) {
  final v = uri.queryParameters['loja']?.toLowerCase();
  return v == 'publica' || v == '1' || v == 'true';
}
