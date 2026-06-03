import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/usuario.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  bool _carregando = true;

  Usuario? get usuario => _usuario;
  bool get carregando => _carregando;
  bool get autenticado => _usuario != null;
  bool get isAdmin => _usuario?.isAdmin ?? false;

  Future<void> inicializar() async {
    _usuario = await AuthService.instance.recuperarSessao();
    _carregando = false;
    notifyListeners();

    // Escuta mudanças de sessão (login Google, logout, etc.)
    AuthService.instance.authStateChanges.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed || event == AuthChangeEvent.userUpdated) {
        final uid = data.session?.user.id;
        if (uid != null) {
          _usuario = await AuthService.instance.recuperarSessao();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _usuario = null;
      }
      notifyListeners();
    });
  }

  Future<bool> loginEmail(String email, String senha) async {
    final user = await AuthService.instance.loginComEmail(email, senha);
    if (user != null) {
      _usuario = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loginGoogle() async {
    await AuthService.instance.loginComGoogle();
    // Resultado chega via authStateChanges
  }

  Future<bool> criarConta(String nome, String email, String senha) async {
    final user = await AuthService.instance.criarConta(nome, email, senha);
    if (user != null) {
      _usuario = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _usuario = null;
    notifyListeners();
  }

  Future<void> atualizarPerfil({String? nome, String? email}) async {
    if (_usuario == null) return;
    await AuthService.instance.atualizarPerfil(_usuario!.id, nome: nome, email: email);
    _usuario = await AuthService.instance.recuperarSessao();
    notifyListeners();
  }

  Future<void> alterarSenha(String novaSenha) async {
    await AuthService.instance.alterarSenha(novaSenha);
  }
}

