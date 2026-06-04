import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const _kBiometricEnabled = 'biometric_enabled';
const _kBiometricEmail = 'biometric_email';
const _kBiometricPassword = 'biometric_password';

/// Login biométrico: credenciais guardadas após login com senha bem-sucedido.
class BiometricAuthService {
  static final BiometricAuthService instance = BiometricAuthService._();
  BiometricAuthService._();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  Future<bool> get dispositivoSuporta async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('biometric isDeviceSupported: $e');
      return false;
    }
  }

  Future<bool> get biometriaDisponivel async {
    if (kIsWeb) return false;
    try {
      final supported = await dispositivoSuporta;
      if (!supported) return false;
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('biometric canCheck: $e');
      return false;
    }
  }

  Future<bool> get habilitado async {
    final v = await _storage.read(key: _kBiometricEnabled);
    return v == 'true';
  }

  Future<void> habilitar({required String email, required String senha}) async {
    await _storage.write(key: _kBiometricEnabled, value: 'true');
    await _storage.write(key: _kBiometricEmail, value: email.trim());
    await _storage.write(key: _kBiometricPassword, value: senha);
  }

  Future<void> desabilitar() async {
    await _storage.delete(key: _kBiometricEnabled);
    await _storage.delete(key: _kBiometricEmail);
    await _storage.delete(key: _kBiometricPassword);
  }

  Future<({String email, String senha})?> lerCredenciais() async {
    if (!await habilitado) return null;
    final email = await _storage.read(key: _kBiometricEmail);
    final senha = await _storage.read(key: _kBiometricPassword);
    if (email == null || senha == null || email.isEmpty) return null;
    return (email: email, senha: senha);
  }

  Future<bool> autenticarBiometria() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Use sua digital ou rosto para entrar no CT SM BJJ',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('autenticarBiometria: $e');
      return false;
    }
  }
}
