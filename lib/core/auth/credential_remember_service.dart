import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLembrar = 'lembrar_credenciais';
const _kEmail = 'credencial_email_salvo';

/// Guarda e-mail/senha localmente quando o usuário marca "Lembrar senha".
class CredentialRememberService {
  static final CredentialRememberService instance = CredentialRememberService._();
  CredentialRememberService._();

  final _secure = const FlutterSecureStorage();

  Future<bool> get lembrarAtivo async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLembrar) ?? false;
  }

  Future<({String email, String senha})?> lerCredenciaisSalvas() async {
    if (!await lembrarAtivo) return null;
    final p = await SharedPreferences.getInstance();
    final email = p.getString(_kEmail);
    final senha = await _secure.read(key: 'credencial_senha_salva');
    if (email == null || email.isEmpty || senha == null || senha.isEmpty) return null;
    return (email: email, senha: senha);
  }

  Future<void> salvar({required bool lembrar, required String email, required String senha}) async {
    final p = await SharedPreferences.getInstance();
    if (!lembrar) {
      await limpar();
      return;
    }
    await p.setBool(_kLembrar, true);
    await p.setString(_kEmail, email.trim());
    await _secure.write(key: 'credencial_senha_salva', value: senha);
  }

  Future<void> limpar() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLembrar, false);
    await p.remove(_kEmail);
    await _secure.delete(key: 'credencial_senha_salva');
  }
}
