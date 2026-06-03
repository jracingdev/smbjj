import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginSenha() async {
    setState(() { _loading = true; _erro = null; });
    final ok = await context.read<AuthProvider>().loginEmail(_emailCtrl.text.trim(), _senhaCtrl.text);
    if (!ok && mounted) {
      setState(() { _erro = 'Email ou senha incorretos.'; _loading = false; });
    }
  }

  Future<void> _loginGoogle() async {
    setState(() { _loading = true; _erro = null; });
    await context.read<AuthProvider>().loginGoogle();
    // Resultado chega via authStateChanges — apenas para loading
    if (mounted) setState(() => _loading = false);
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
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset('assets/images/logo.png', width: 90, height: 90, errorBuilder: (_, __, ___) =>
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(50)),
                      child: const Icon(Icons.sports_martial_arts, size: 48, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('CT SM BJJ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('Academia de Jiu-Jitsu', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 40),

                // Card login
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Entrar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const SizedBox(height: 20),

                      if (_erro != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Text(_erro!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _senhaCtrl,
                        decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _loading ? null : _loginSenha,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Entrar'),
                      ),

                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ]),
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
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CriarContaScreen())),
                        child: const Text('Não tem conta? Criar agora', style: TextStyle(color: verdeEscuro)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('SM BJJ © 2018 · Todos os direitos reservados', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
