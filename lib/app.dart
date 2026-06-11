import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/theme.dart';
import 'core/loja/loja_publica_pending.dart';
import 'screens/auth/login_screen.dart';
import 'screens/loja/loja_publica_screen.dart';
import 'widgets/cadastro_gate.dart';

class CtSmBjjApp extends StatelessWidget {
  const CtSmBjjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CT SM BJJ',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (LojaPublicaPending.ativo && !auth.autenticado) {
            return const LojaPublicaScreen();
          }
          if (auth.carregando) {
            return const Scaffold(
              backgroundColor: verdeEscuro,
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          return auth.autenticado ? const CadastroGate() : const LoginScreen();
        },
      ),
    );
  }
}
