import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/aluno.dart';
import '../../models/usuario.dart';
import '../../repositories/aluno_repository.dart';
import 'auth_result.dart';
import 'auth_service.dart';
import 'biometric_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  Aluno? _alunoVinculado;
  bool _carregando = true;
  bool _carregandoAluno = false;
  String? _mensagemAuth;
  final _alunoRepo = AlunoRepository();

  Usuario? get usuario => _usuario;
  Aluno? get alunoVinculado => _alunoVinculado;
  bool get carregando => _carregando;
  bool get carregandoAluno => _carregandoAluno;
  String? get mensagemAuth => _mensagemAuth;
  bool get autenticado => _usuario != null;
  bool get isAdmin => _usuario?.isAdmin ?? false;

  /// Primeiro acesso ou cadastro incompleto: exibe formulário obrigatório.
  bool get precisaCompletarCadastro {
    if (isAdmin || _usuario == null) return false;
    final aluno = _alunoVinculado;
    if (aluno == null) return true;
    return !aluno.cadastroCompleto;
  }

  bool get aguardandoValidacao =>
      !isAdmin &&
      _alunoVinculado != null &&
      _alunoVinculado!.cadastroCompleto &&
      !_alunoVinculado!.cadastroValidado;

  Future<void> inicializar() async {
    try {
      _usuario = await AuthService.instance.recuperarSessao();
    } catch (e, st) {
      debugPrint('AuthProvider.inicializar sessão: $e\n$st');
    } finally {
      _carregando = false;
      notifyListeners();
    }
    if (_usuario != null && !isAdmin) {
      await _atualizarVinculoAluno();
    }

    AuthService.instance.authStateChanges.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        final user = data.session?.user ?? Supabase.instance.client.auth.currentUser;
        if (user != null) {
          _usuario = await AuthService.instance.ensurePerfilUsuario(user);
          if (_usuario != null && !isAdmin) {
            await _atualizarVinculoAluno();
          } else {
            _alunoVinculado = null;
            notifyListeners();
          }
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _usuario = null;
        _alunoVinculado = null;
        _carregandoAluno = false;
        notifyListeners();
      }
    });
  }

  Future<void> _carregarAlunoVinculado() async {
    if (_usuario == null || isAdmin) {
      _alunoVinculado = null;
      return;
    }
    try {
      if (_usuario!.alunoId != null) {
        _alunoVinculado = await _alunoRepo.buscarPorId(_usuario!.alunoId!);
      }
      _alunoVinculado ??= await _alunoRepo.buscarPorEmail(_usuario!.email);
      if (_alunoVinculado != null && _usuario!.alunoId == null) {
        await AuthService.instance.vincularAluno(_usuario!.id, _alunoVinculado!.id);
        _usuario = _usuario!.copyWith(alunoId: _alunoVinculado!.id);
      }
    } catch (e, st) {
      debugPrint('AuthProvider._carregarAlunoVinculado: $e\n$st');
      _mensagemAuth = 'Não foi possível carregar seu cadastro. Tente novamente em instantes.';
    }
  }

  Future<void> _atualizarVinculoAluno() async {
    _carregandoAluno = true;
    notifyListeners();
    try {
      await _carregarAlunoVinculado();
    } finally {
      _carregandoAluno = false;
      notifyListeners();
    }
  }

  Future<void> recarregarAluno() async {
    await _atualizarVinculoAluno();
  }

  Future<AuthResult> loginEmail(String email, String senha) async {
    final result = await AuthService.instance.loginComEmail(email, senha);
    _mensagemAuth = result.message;
    if (result.usuario != null) {
      _usuario = result.usuario;
      if (!isAdmin) {
        await _atualizarVinculoAluno();
      } else {
        notifyListeners();
      }
    }
    return result;
  }

  Future<AuthResult> loginGoogle() async {
    final result = await AuthService.instance.loginComGoogle();
    _mensagemAuth = result.message;
    if (result.usuario != null) {
      _usuario = result.usuario;
      if (!isAdmin) {
        await _atualizarVinculoAluno();
      } else {
        notifyListeners();
      }
    }
    return result;
  }

  Future<AuthResult> recuperarSenha(String email) async {
    final result = await AuthService.instance.recuperarSenha(email);
    _mensagemAuth = result.message;
    notifyListeners();
    return result;
  }

  /// Valida a senha atual, confirma biometria e grava credenciais para login rápido.
  Future<AuthResult> configurarBiometria(String senha) async {
    final email = _usuario?.email.trim();
    if (email == null || email.isEmpty) {
      return const AuthResult(
        status: AuthStatus.error,
        message: 'E-mail do usuário não encontrado.',
      );
    }
    if (!await BiometricAuthService.instance.biometriaDisponivel) {
      return const AuthResult(
        status: AuthStatus.error,
        message: 'Este aparelho não suporta biometria ou PIN de bloqueio.',
      );
    }
    final bioOk = await BiometricAuthService.instance.autenticarBiometria();
    if (!bioOk) {
      return const AuthResult(
        status: AuthStatus.error,
        message: 'Biometria cancelada ou não reconhecida.',
      );
    }
    final check = await AuthService.instance.loginComEmail(email, senha);
    if (!check.ok) {
      return AuthResult(
        status: AuthStatus.error,
        message: check.message ?? 'Senha incorreta.',
      );
    }
    await BiometricAuthService.instance.habilitar(email: email, senha: senha);
    return const AuthResult(
      status: AuthStatus.success,
      message: 'Biometria ativada! Use na tela de entrar.',
    );
  }

  Future<AuthResult> loginBiometrico() async {
    final creds = await BiometricAuthService.instance.lerCredenciais();
    if (creds == null) {
      return const AuthResult(
        status: AuthStatus.error,
        message: 'Login biométrico não configurado. Entre com e-mail e senha.',
      );
    }
    final ok = await BiometricAuthService.instance.autenticarBiometria();
    if (!ok) {
      return const AuthResult(
        status: AuthStatus.error,
        message: 'Autenticação biométrica cancelada ou falhou.',
      );
    }
    return loginEmail(creds.email, creds.senha);
  }

  Future<AuthResult> criarConta(String nome, String email, String senha) async {
    final result = await AuthService.instance.criarConta(nome, email, senha);
    _mensagemAuth = result.message;
    if (result.usuario != null) {
      _usuario = result.usuario;
      if (!isAdmin) {
        await _atualizarVinculoAluno();
      } else {
        notifyListeners();
      }
    }
    return result;
  }

  Future<void> vincularAlunoSalvo(Aluno aluno) async {
    if (_usuario == null) return;
    await AuthService.instance.vincularAluno(_usuario!.id, aluno.id);
    _usuario = _usuario!.copyWith(alunoId: aluno.id);
    _alunoVinculado = aluno;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _usuario = null;
    _alunoVinculado = null;
    _mensagemAuth = null;
    _carregandoAluno = false;
    notifyListeners();
  }

  Future<void> atualizarPerfil({String? nome, String? email}) async {
    if (_usuario == null) return;
    await AuthService.instance.atualizarPerfil(_usuario!.id, nome: nome, email: email);
    _usuario = await AuthService.instance.recuperarSessao();
    if (!isAdmin) {
      await _atualizarVinculoAluno();
    } else {
      notifyListeners();
    }
  }

  Future<void> alterarSenha(String novaSenha) async {
    await AuthService.instance.alterarSenha(novaSenha);
  }
}
