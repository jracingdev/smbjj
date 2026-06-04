import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_platform.dart';
import 'core/app_version.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/google_native_sign_in.dart';
import 'core/supabase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersion.init();

  if (isNativeApp && GoogleNativeSignIn.disponivel) {
    try {
      await GoogleNativeSignIn.ensureInitialized();
    } catch (e, st) {
      debugPrint('GoogleSignIn init: $e\n$st');
    }
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final authProvider = AuthProvider();
  await authProvider.inicializar();

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const CtSmBjjApp(),
    ),
  );
}
