import 'package:flutter/material.dart';
import 'biometric_auth_service.dart';

/// Oferta de biometria após login — exibida na tela principal (não na login, que é descartada).
class BiometricOfferHelper {
  static String? _emailPendente;
  static String? _senhaPendente;
  static bool _exibindo = false;

  static void agendar({required String email, required String senha}) {
    _emailPendente = email.trim();
    _senhaPendente = senha;
  }

  static Future<void> tentarExibir(BuildContext context) async {
    final email = _emailPendente;
    final senha = _senhaPendente;
    if (email == null || senha == null || email.isEmpty) return;
    if (_exibindo) return;
    if (!context.mounted) return;
    if (!await BiometricAuthService.instance.biometriaDisponivel) {
      limpar();
      return;
    }
    if (await BiometricAuthService.instance.habilitado) {
      limpar();
      return;
    }

    _exibindo = true;
    try {
      final ativar = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Login biométrico'),
          content: const Text(
            'Deseja usar digital ou reconhecimento facial para entrar da próxima vez?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
              child: const Text('Agora não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
              child: const Text('Ativar'),
            ),
          ],
        ),
      );

      if (ativar == true) {
        final bioOk = await BiometricAuthService.instance.autenticarBiometria();
        if (bioOk) {
          await BiometricAuthService.instance.habilitar(email: email, senha: senha);
        }
      }
    } finally {
      limpar();
      _exibindo = false;
    }
  }

  static void limpar() {
    _emailPendente = null;
    _senhaPendente = null;
  }
}
