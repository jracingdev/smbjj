import '../auth/oauth_config.dart';

/// URL pública no QR — funciona no app Android, web e câmera do iPhone.
String urlCheckinPresenca(String token) {
  final base = Uri.parse(OAuthConfig.webRedirect);
  return base.replace(queryParameters: {'checkin': token}).toString();
}

/// Extrai token de uma URL ou string escaneada.
String? tokenDeUrlOuQr(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final uri = Uri.tryParse(t);
  if (uri != null) {
    final q = uri.queryParameters['checkin'];
    if (q != null && q.isNotEmpty) return q;
  }
  if (RegExp(r'^[a-f0-9]{32}$', caseSensitive: false).hasMatch(t)) return t;
  return null;
}
