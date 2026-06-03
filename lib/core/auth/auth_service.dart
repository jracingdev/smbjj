import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import '../../models/usuario.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<Usuario?> loginComEmail(String email, String senha) async {
    try {
      final res = await supabase.auth.signInWithPassword(email: email, password: senha);
      if (res.user == null) return null;
      return await _buscarPerfil(res.user!.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loginComGoogle() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<Usuario?> criarConta(String nome, String email, String senha) async {
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: senha,
        data: {'full_name': nome},
      );
      if (res.user == null) return null;
      await Future.delayed(const Duration(milliseconds: 800));
      return await _buscarPerfil(res.user!.id);
    } catch (_) {
      return null;
    }
  }

  Future<Usuario?> recuperarSessao() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;
    return await _buscarPerfil(session.user.id);
  }

  Future<Usuario?> _buscarPerfil(String uid) async {
    try {
      final data = await supabase
          .from('usuarios')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (data == null) return null;
      return Usuario.fromMap({...data, 'id': uid});
    } catch (_) {
      return null;
    }
  }

  Future<void> atualizarPerfil(String uid, {String? nome, String? email}) async {
    final updates = <String, dynamic>{};
    if (nome != null) updates['nome'] = nome;
    if (email != null) updates['email'] = email;
    if (updates.isNotEmpty) {
      await supabase.from('usuarios').update(updates).eq('id', uid);
    }
    if (email != null) {
      await supabase.auth.updateUser(UserAttributes(email: email));
    }
  }

  Future<void> alterarSenha(String novaSenha) async {
    await supabase.auth.updateUser(UserAttributes(password: novaSenha));
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
