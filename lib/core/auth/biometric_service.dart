import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBiometricEnabled = 'biometric_login_enabled';

class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final _auth = LocalAuthentication();
  final _secure = const FlutterSecureStorage();

  Future<bool> dispositivoSuporta() async {
    if (kIsWeb) return false;
    try {
      final ok = await _auth.isDeviceSupported();
      final tipos = await _auth.getAvailableBiometrics();
      return ok && tipos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> estaHabilitado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  Future<void> setHabilitado(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
    if (!value) {
      await _secure.delete(key: 'bio_email');
      await _secure.delete(key: 'bio_password');
    }
  }

  Future<void> salvarCredenciais(String email, String password) async {
    await _secure.write(key: 'bio_email', value: email.trim());
    await _secure.write(key: 'bio_password', value: password);
    await setHabilitado(true);
  }

  Future<({String email, String password})?> lerCredenciais() async {
    final email = await _secure.read(key: 'bio_email');
    final pass = await _secure.read(key: 'bio_password');
    if (email == null || pass == null || email.isEmpty) return null;
    return (email: email, password: pass);
  }

  Future<bool> autenticar({String reason = 'Use biometria para entrar no CT SM BJJ'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (e) {
      debugPrint('biometric auth: $e');
      return false;
    }
  }
}
