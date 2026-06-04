import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_platform.dart';
import '../supabase_service.dart';
import 'oauth_config.dart';

/// Login Google nativo no Android/iOS (sem navegador nem deep link).
class GoogleNativeSignIn {
  static bool _initialized = false;

  /// Só no APK/IPA — na web quebra o boot se inicializar GoogleSignIn.
  static bool get disponivel =>
      isNativeApp && OAuthConfig.googleWebClientId.trim().isNotEmpty;

  static Future<void> ensureInitialized() async {
    if (_initialized || !disponivel) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: OAuthConfig.googleWebClientId.trim(),
    );
    _initialized = true;
  }

  /// Retorna [AuthResponse] em sucesso; null se o usuário cancelou.
  static Future<AuthResponse?> signIn() async {
    if (!disponivel) return null;

    await ensureInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('Google authenticate não suportado nesta plataforma.');
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google não retornou idToken. Verifique o Web Client ID no Supabase/Google Cloud.');
    }

    final authorization = await account.authorizationClient
            .authorizationForScopes(const ['email', 'profile']) ??
        await account.authorizationClient.authorizeScopes(const ['email', 'profile']);

    final accessToken = authorization.accessToken;
    if (accessToken.isEmpty) {
      throw StateError('Google não retornou accessToken.');
    }

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
