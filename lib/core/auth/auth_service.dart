import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import '../../models/usuario.dart';
import 'auth_result.dart';

/// Apenas estes e-mails podem ter role admin (case-insensitive).
const Set<String> kAdminEmails = {
  'admin@smbj.com',
};

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static String roleForEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized != null && kAdminEmails.contains(normalized)) {
      return 'admin';
    }
    return 'aluno';
  }

  Future<AuthResult> loginComEmail(String email, String senha) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: senha,
      );
      if (res.user == null) {
        return const AuthResult(status: AuthStatus.error, message: 'Email ou senha incorretos.');
      }
      final usuario = await ensurePerfilUsuario(res.user!);
      if (usuario == null) {
        return const AuthResult(
          status: AuthStatus.error,
          message: 'Não foi possível carregar seu perfil. Tente novamente.',
        );
      }
      return AuthResult(status: AuthStatus.success, usuario: usuario);
    } on AuthException catch (e) {
      return AuthResult(status: AuthStatus.error, message: _mensagemAuth(e));
    } catch (e) {
      debugPrint('loginComEmail: $e');
      return const AuthResult(status: AuthStatus.error, message: 'Erro ao entrar. Verifique sua conexão.');
    }
  }

  Future<AuthResult> loginComGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return const AuthResult(status: AuthStatus.success);
    } on AuthException catch (e) {
      return AuthResult(status: AuthStatus.error, message: _mensagemAuth(e));
    } catch (e) {
      debugPrint('loginComGoogle: $e');
      return const AuthResult(status: AuthStatus.error, message: 'Não foi possível abrir o login Google.');
    }
  }

  Future<AuthResult> criarConta(String nome, String email, String senha) async {
    try {
      final res = await supabase.auth.signUp(
        email: email.trim(),
        password: senha,
        data: {'full_name': nome.trim()},
      );
      if (res.user == null) {
        return const AuthResult(status: AuthStatus.error, message: 'Não foi possível criar a conta.');
      }

      if (res.session == null) {
        return const AuthResult(
          status: AuthStatus.needsEmailConfirmation,
          message:
              'Conta criada! Verifique seu e-mail e confirme o cadastro antes de entrar.',
        );
      }

      final usuario = await ensurePerfilUsuario(res.user!, nome: nome.trim());
      if (usuario == null) {
        return const AuthResult(
          status: AuthStatus.error,
          message: 'Conta criada, mas o perfil não foi gerado. Tente entrar em alguns segundos.',
        );
      }
      return AuthResult(status: AuthStatus.success, usuario: usuario);
    } on AuthException catch (e) {
      final msg = _mensagemAuth(e);
      if (msg.toLowerCase().contains('already') || msg.toLowerCase().contains('registered')) {
        return const AuthResult(status: AuthStatus.error, message: 'Este e-mail já está cadastrado.');
      }
      return AuthResult(status: AuthStatus.error, message: msg);
    } catch (e) {
      debugPrint('criarConta: $e');
      return const AuthResult(status: AuthStatus.error, message: 'Erro ao criar conta. Tente novamente.');
    }
  }

  Future<Usuario?> recuperarSessao() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return ensurePerfilUsuario(user);
  }

  /// Garante linha em public.usuarios com role segura (sempre aluno, exceto allowlist).
  Future<Usuario?> ensurePerfilUsuario(User user, {String? nome}) async {
    final uid = user.id;
    var perfil = await _buscarPerfil(uid);
    if (perfil != null) {
      return _corrigirRoleAdminIndevido(perfil);
    }

    for (var i = 0; i < 6; i++) {
      await Future.delayed(Duration(milliseconds: 250 + i * 150));
      perfil = await _buscarPerfil(uid);
      if (perfil != null) return _corrigirRoleAdminIndevido(perfil);
    }

    final email = user.email?.trim() ?? '';
    if (email.isEmpty) return null;

    final role = roleForEmail(email);
    final nomePerfil = nome ??
        (user.userMetadata?['full_name'] as String?) ??
        (user.userMetadata?['name'] as String?) ??
        email.split('@').first;

    try {
      await supabase.from('usuarios').insert({
        'id': uid,
        'nome': nomePerfil,
        'email': email,
        'role': role,
        if (user.userMetadata?['avatar_url'] != null)
          'foto_url': user.userMetadata!['avatar_url'],
      });
    } on PostgrestException catch (e) {
      debugPrint('ensurePerfil insert: ${e.message}');
    } catch (e) {
      debugPrint('ensurePerfil insert: $e');
    }

    perfil = await _buscarPerfil(uid);
    if (perfil != null) return _corrigirRoleAdminIndevido(perfil);
    return null;
  }

  Future<Usuario?> _corrigirRoleAdminIndevido(Usuario u) async {
    if (u.isAdmin && roleForEmail(u.email) != 'admin') {
      debugPrint('Corrigindo role admin indevido para ${u.email}');
      try {
        await supabase.from('usuarios').update({'role': 'aluno'}).eq('id', u.id);
        return _buscarPerfil(u.id);
      } catch (e) {
        debugPrint('Falha ao corrigir role: $e');
      }
    }
    return u;
  }

  Future<Usuario?> _buscarPerfil(String uid) async {
    try {
      final data = await supabase.from('usuarios').select().eq('id', uid).maybeSingle();
      if (data == null) return null;
      return Usuario.fromMap({...data, 'id': uid});
    } catch (e) {
      debugPrint('_buscarPerfil: $e');
      return null;
    }
  }

  String _mensagemAuth(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Email ou senha incorretos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    return e.message;
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

  Future<AuthResult> recuperarSenha(String email) async {
    final e = email.trim();
    if (e.isEmpty || !e.contains('@')) {
      return const AuthResult(status: AuthStatus.error, message: 'Informe um e-mail válido.');
    }
    try {
      await supabase.auth.resetPasswordForEmail(
        e,
        redirectTo: kIsWeb ? 'https://jracingdev.github.io/smbjj/' : null,
      );
      return const AuthResult(
        status: AuthStatus.success,
        message: 'Link enviado! Abra o e-mail para definir uma nova senha.',
      );
    } on AuthException catch (ex) {
      return AuthResult(status: AuthStatus.error, message: _mensagemAuth(ex));
    } catch (e) {
      debugPrint('recuperarSenha: $e');
      return const AuthResult(
        status: AuthStatus.error,
        message: 'Não foi possível enviar o e-mail. Tente novamente.',
      );
    }
  }

  Future<void> vincularAluno(String userId, String alunoId) async {
    await supabase.from('usuarios').update({'aluno_id': alunoId}).eq('id', userId);
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
