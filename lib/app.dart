import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_platform.dart';
import 'core/auth/auth_provider.dart';
import 'core/loja/loja_publica_pending.dart';
import 'core/loja/loja_publica_url.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/loja/loja_publica_screen.dart';
import 'widgets/cadastro_gate.dart';

class CtSmBjjApp extends StatefulWidget {
  const CtSmBjjApp({super.key});

  @override
  State<CtSmBjjApp> createState() => _CtSmBjjAppState();
}

class _CtSmBjjAppState extends State<CtSmBjjApp> {
  @override
  void initState() {
    super.initState();
    sincronizarLojaPublicaDaUrl();
  }

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
          sincronizarLojaPublicaDaUrl();

          if (auth.carregando) {
            return const Scaffold(
              backgroundColor: verdeEscuro,
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          if (auth.autenticado) {
            return const CadastroGate();
          }

          // Web: home = loja e-commerce; app nativo = login.
          if (isWebApp || LojaPublicaPending.ativo) {
            return const LojaPublicaScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
