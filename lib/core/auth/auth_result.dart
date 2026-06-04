import '../../models/usuario.dart';

enum AuthStatus {
  success,
  needsEmailConfirmation,
  error,
}

class AuthResult {
  final AuthStatus status;
  final Usuario? usuario;
  final String? message;

  const AuthResult({
    required this.status,
    this.usuario,
    this.message,
  });

  bool get ok => status == AuthStatus.success;

  bool get sessaoIniciada => status == AuthStatus.success && usuario != null;
}
