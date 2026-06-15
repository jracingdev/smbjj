import '../constants.dart';
import '../app_platform.dart';
import 'loja_publica_pending.dart';
import 'loja_publica_url_stub.dart' if (dart.library.html) 'loja_publica_url_web.dart';

String urlLojaPublica() => lojaPublicaWebUrl;

bool urlEhLojaPublica(Uri uri) {
  final v = uri.queryParameters['loja']?.toLowerCase();
  return v == 'publica' || v == '1' || v == 'true';
}

/// Na web, visitantes veem a loja na home (smbjj.com.br).
bool get lojaComoHomeWeb => isWebApp;

void sincronizarLojaPublicaDaUrl() {
  if (lojaComoHomeWeb || urlEhLojaPublica(currentLaunchUri)) {
    LojaPublicaPending.ativar();
  } else {
    LojaPublicaPending.desativar();
  }
}
