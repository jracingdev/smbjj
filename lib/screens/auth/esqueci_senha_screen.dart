import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key, this.emailInicial});

  final String? emailInicial;

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  late final _emailCtrl = TextEditingController(text: widget.emailInicial ?? '');
  bool _loading = false;
  String? _msg;
  bool _sucesso = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _msg = 'Informe um e-mail válido.');
      return;
    }
    setState(() {
      _loading = true;
      _msg = null;
      _sucesso = false;
    });
    final result = await context.read<AuthProvider>().recuperarSenha(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sucesso = result.ok;
      _msg = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enviaremos um link para o seu e-mail redefinir a senha.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'E-mail da conta',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_msg != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _sucesso ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_msg!, style: TextStyle(color: _sucesso ? Colors.green.shade800 : Colors.red.shade700, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _enviar,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enviar link de recuperação'),
            ),
            if (_sucesso)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar ao login', style: TextStyle(color: verdeEscuro)),
              ),
          ],
        ),
      ),
    );
  }
}
