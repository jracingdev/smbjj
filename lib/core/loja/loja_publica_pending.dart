/// Abre a loja pública ao iniciar (URL ?loja=publica).
class LojaPublicaPending {
  static bool _ativo = false;

  static bool get ativo => _ativo;

  static void ativar() => _ativo = true;

  static void desativar() => _ativo = false;
}
