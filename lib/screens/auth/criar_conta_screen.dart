import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_platform.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_result.dart';
import '../../core/legal/termo_aceite_service.dart';
import '../../core/theme.dart';
import '../legal/legal_document_screen.dart';

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
  bool _aceitouTermos = false;
  bool _aceitouAptidao = false;
  bool _pendenteAceiteGoogle = false;
  String? _erro;
  String? _sucesso;
  AuthProvider? _authProv;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProv = context.read<AuthProvider>();
      _authProv!.addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    if (!mounted || _authProv == null) return;
    if (_authProv!.autenticado) {
      if (_pendenteAceiteGoogle) {
        _pendenteAceiteGoogle = false;
        _registrarAceites(
          nome: _authProv!.usuario?.nome ?? _nomeCtrl.text.trim(),
          email: _authProv!.usuario?.email ?? _emailCtrl.text.trim(),
          userId: _authProv!.usuario?.id,
        );
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _registrarAceites({
    required String nome,
    required String email,
    String? userId,
  }) async {
    await TermoAceiteService.instance.registrarAceitesCadastro(
      nome: nome,
      email: email,
      userId: userId,
      termosUso: _aceitouTermos,
      aptidaoFisica: _aceitouAptidao,
    );
  }

  @override
  void dispose() {
    _authProv?.removeListener(_onAuthChanged);
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (!_aceitouTermos) {
      setState(() => _erro = 'Aceite os Termos de Uso e a Política de Privacidade para continuar.');
      return;
    }
    if (!_aceitouAptidao) {
      setState(() => _erro = 'Aceite o Termo de Aptidão Física e Responsabilidade para continuar.');
      return;
    }
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
        final auth = context.read<AuthProvider>();
        await _registrarAceites(
          nome: _nomeCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          userId: auth.usuario?.id,
        );
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      setState(() => _erro = result.message ?? 'Não foi possível criar a conta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _criarComGoogle() async {
    if (!_aceitouTermos) {
      setState(() => _erro = 'Aceite os Termos de Uso e a Política de Privacidade para continuar.');
      return;
    }
    if (!_aceitouAptidao) {
      setState(() => _erro = 'Aceite o Termo de Aptidão Física e Responsabilidade para continuar.');
      return;
    }
    _pendenteAceiteGoogle = true;
    setState(() {
      _loading = true;
      _erro = null;
      _sucesso = null;
    });
    final result = await context.read<AuthProvider>().loginGoogle();
    if (!mounted) return;
    if (result.status == AuthStatus.error) {
      setState(() {
        _erro = result.message;
        _loading = false;
      });
    } else if (result.status != AuthStatus.oauthStarted) {
      setState(() => _loading = false);
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
                  isNativeApp
                      ? 'Use Google ou e-mail. Depois preencha os dados da academia que o Google não traz (telefone, cidade, etc.).'
                      : 'Na web, use Google ou e-mail. Complete o cadastro da academia após entrar.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _criarComGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 22),
                  label: const Text('Criar conta com Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('ou e-mail', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ]),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _aceitouTermos,
                      activeColor: verdeEscuro,
                      onChanged: _loading ? null : (v) => setState(() => _aceitouTermos = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : () => setState(() => _aceitouTermos = !_aceitouTermos),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            children: [
                              Text('Li e aceito os ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              GestureDetector(
                                onTap: () => LegalDocumentScreen.abrir(context, LegalDoc.termos),
                                child: const Text('Termos de Uso', style: TextStyle(fontSize: 12, color: verdeEscuro, fontWeight: FontWeight.w700)),
                              ),
                              Text(' e a ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              GestureDetector(
                                onTap: () => LegalDocumentScreen.abrir(context, LegalDoc.privacidade),
                                child: const Text('Política de Privacidade', style: TextStyle(fontSize: 12, color: verdeEscuro, fontWeight: FontWeight.w700)),
                              ),
                              Text('.', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _aceitouAptidao,
                      activeColor: verdeEscuro,
                      onChanged: _loading ? null : (v) => setState(() => _aceitouAptidao = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : () => setState(() => _aceitouAptidao = !_aceitouAptidao),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Li e Concordo — Aptidão Física',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: verdeEscuro),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Declaro aptidão para Jiu-Jitsu, assumo os riscos da prática e isento a Marinho Team Jiu-Jitsu. '
                                'Sou maior de 18 anos ou tenho autorização do responsável legal. '
                                'Detalhes no Termo de Aptidão dentro dos Termos de Uso.',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
