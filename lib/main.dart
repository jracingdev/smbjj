import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_provider.dart';
import 'core/supabase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
