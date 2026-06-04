import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_result.dart';
import '../../core/theme.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;
  String? _sucesso;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Informe seu nome completo.');
      return;
    }
    if (_senhaCtrl.text != _confirmaSenhaCtrl.text) {
      setState(() {
        _erro = 'As senhas não coincidem.';
        _sucesso = null;
      });
      return;
    }
    if (_senhaCtrl.text.length < 6) {
      setState(() {
        _erro = 'A senha deve ter pelo menos 6 caracteres.';
        _sucesso = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
      _sucesso = null;
    });

    try {
      final result = await context.read<AuthProvider>().criarConta(
            _nomeCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _senhaCtrl.text,
          );

      if (!mounted) return;

      if (result.status == AuthStatus.needsEmailConfirmation) {
        setState(() => _sucesso = result.message);
        return;
      }

      if (result.sessaoIniciada) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      setState(() => _erro = result.message ?? 'Não foi possível criar a conta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: verdeEscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Criar Conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Novo Cadastro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  'Após criar a conta, você preencherá seu cadastro na academia para o professor validar e definir sua turma.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
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
                if (_sucesso != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_sucesso!, style: TextStyle(color: Colors.green.shade800, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _senhaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Senha *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmaSenhaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Senha *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  onSubmitted: (_) => _loading ? null : _criar(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _criar,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Criar Conta'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Já tenho conta', style: TextStyle(color: verdeEscuro)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
