import '../constants.dart';
import 'loja_publica_pending.dart';
import 'loja_publica_url_stub.dart' if (dart.library.html) 'loja_publica_url_web.dart';

String urlLojaPublica() => lojaPublicaWebUrl;

bool urlEhLojaPublica(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host == lojaPublicaHost) return true;
  final v = uri.queryParameters['loja']?.toLowerCase();
  return v == 'publica' || v == '1' || v == 'true';
}

/// Ativa a loja pública a partir da URL atual (web ou deep link).
void sincronizarLojaPublicaDaUrl() {
  if (urlEhLojaPublica(currentLaunchUri)) {
    LojaPublicaPending.ativar();
  } else {
    LojaPublicaPending.desativar();
  }
}
