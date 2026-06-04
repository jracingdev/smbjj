import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_result.dart';
import '../../core/auth/biometric_auth_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'criar_conta_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;
  bool _biometriaDisponivel = false;
  bool _biometriaHabilitada = false;

  @override
  void initState() {
    super.initState();
    _carregarBiometria();
  }

  Future<void> _carregarBiometria() async {
    final bio = BiometricAuthService.instance;
    final disp = await bio.biometriaDisponivel;
    final hab = await bio.habilitado;
    if (mounted) {
      setState(() {
        _biometriaDisponivel = disp;
        _biometriaHabilitada = hab;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _oferecerBiometria(String email, String senha) async {
    if (!await BiometricAuthService.instance.biometriaDisponivel) return;
    if (await BiometricAuthService.instance.habilitado) return;
    if (!mounted) return;

    final ativar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login biométrico'),
        content: const Text(
          'Deseja usar digital ou reconhecimento facial para entrar da próxima vez?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Agora não')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ativar')),
        ],
      ),
    );
    if (ativar == true) {
      await BiometricAuthService.instance.habilitar(email: email, senha: senha);
      if (mounted) await _carregarBiometria();
    }
  }

  Future<void> _loginSenha() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      final senha = _senhaCtrl.text;
      final result = await context.read<AuthProvider>().loginEmail(email, senha);
      if (!mounted) return;
      if (!result.ok) {
        setState(() => _erro = result.message ?? 'Email ou senha incorretos.');
      } else {
        await _oferecerBiometria(email, senha);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginBiometrico() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final result = await context.read<AuthProvider>().loginBiometrico();
      if (!mounted) return;
      if (!result.ok) {
        setState(() => _erro = result.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final result = await context.read<AuthProvider>().loginGoogle();
      if (!mounted) return;
      if (result.status == AuthStatus.error) {
        setState(() => _erro = result.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _esqueceuSenha() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final enviado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Esqueceu a senha?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Informe seu e-mail. Enviaremos um link para redefinir a senha.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
    final emailEnviar = emailCtrl.text.trim();
    emailCtrl.dispose();
    if (enviado != true || !mounted) return;

    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().recuperarSenha(emailEnviar);
    if (!mounted) return;
    setState(() => _loading = false);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(result.ok ? 'E-mail enviado' : 'Não foi possível enviar'),
        content: Text(result.message ?? ''),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _biometriaNaoConfigurada() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Entre com e-mail e senha uma vez. Depois aceite "Ativar" no aviso para usar biometria.',
        ),
        backgroundColor: verdeEscuro,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [verdeEscuro, Color(0xFF145521)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.sports_martial_arts, size: 48, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'CT SM BJJ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Text(
                  'Academia de Jiu-Jitsu',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        academiaCredenciada,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        academiaCredencial,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      Text(
                        'v$appVersion',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      if (_biometriaDisponivel) ...[
                        if (_biometriaHabilitada)
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _loginBiometrico,
                            icon: const Icon(Icons.fingerprint, size: 26),
                            label: const Text(
                              'Entrar com biometria',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: verdeEscuro,
                              side: const BorderSide(color: verdeEscuro, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _biometriaNaoConfigurada,
                            icon: Icon(Icons.fingerprint, size: 26, color: Colors.grey.shade600),
                            label: Text(
                              'Biometria (ative após 1º login)',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('ou e-mail', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_erro != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_erro!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _senhaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        onSubmitted: (_) => _loading ? null : _loginSenha(),
                      ),
                      const SizedBox(height: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loading ? null : _esqueceuSenha,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_reset, size: 18, color: verdeEscuro),
                                const SizedBox(width: 6),
                                const Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: verdeEscuro,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loading ? null : _loginSenha,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _loginGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 22),
                        label: const Text('Entrar com Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CriarContaScreen()),
                                ),
                        child: const Text(
                          'Não tem conta? Criar agora',
                          style: TextStyle(color: verdeEscuro),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SM BJJ © 2018 · Todos os direitos reservados',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
