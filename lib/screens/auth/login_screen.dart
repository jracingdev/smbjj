import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_platform.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_result.dart';
import '../../core/auth/biometric_auth_service.dart';
import '../../core/auth/credential_remember_service.dart';
import '../../core/app_version.dart';
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
  bool _tentouBioAuto = false;
  bool _lembrarSenha = false;
  bool _aguardandoGoogle = false;
  AuthProvider? _authProv;

  @override
  void initState() {
    super.initState();
    _carregarInicio();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (_authProv != auth) {
      _authProv?.removeListener(_onAuthChanged);
      _authProv = auth;
      _authProv!.addListener(_onAuthChanged);
    }
  }

  void _onAuthChanged() {
    if (!mounted || _authProv == null) return;
    if (_aguardandoGoogle && _authProv!.autenticado) {
      setState(() {
        _aguardandoGoogle = false;
        _loading = false;
      });
    }
  }

  Future<void> _carregarInicio() async {
    final credSvc = CredentialRememberService.instance;
    final bio = BiometricAuthService.instance;
    final results = await Future.wait([
      credSvc.lerCredenciaisSalvas(),
      credSvc.lembrarAtivo,
      bio.biometriaDisponivel,
      bio.habilitado,
    ]);
    final creds = results[0] as ({String email, String senha})?;
    final lembrar = results[1] as bool;
    final disp = results[2] as bool;
    final hab = results[3] as bool;

    if (mounted) {
      setState(() {
        _lembrarSenha = lembrar;
        _biometriaDisponivel = disp;
        _biometriaHabilitada = hab;
        if (creds != null) {
          _emailCtrl.text = creds.email;
          _senhaCtrl.text = creds.senha;
        }
      });
    }
    if (hab && disp && isNativeApp && mounted && !_tentouBioAuto) {
      _tentouBioAuto = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loginBiometrico());
    }
  }

  Future<void> _recarregarBiometria() async {
    final hab = await BiometricAuthService.instance.habilitado;
    if (mounted) setState(() => _biometriaHabilitada = hab);
  }

  @override
  void dispose() {
    _authProv?.removeListener(_onAuthChanged);
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _oferecerBiometria(String email, String senha) async {
    if (!isNativeApp) return;
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
      if (mounted) await _recarregarBiometria();
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
        await CredentialRememberService.instance.salvar(
          lembrar: _lembrarSenha,
          email: email,
          senha: senha,
        );
        await _oferecerBiometria(email, senha);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginBiometrico() async {
    if (!isNativeApp) {
      _biometriaNaoConfigurada(web: true);
      return;
    }
    if (!_biometriaHabilitada) {
      _biometriaNaoConfigurada();
      return;
    }
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
      _aguardandoGoogle = true;
    });
    try {
      final result = await context.read<AuthProvider>().loginGoogle();
      if (!mounted) return;
      if (result.status == AuthStatus.error) {
        setState(() {
          _erro = result.message;
          _aguardandoGoogle = false;
        });
      } else if (result.status == AuthStatus.success) {
        setState(() {
          _aguardandoGoogle = false;
          _loading = false;
        });
      } else if (result.status == AuthStatus.oauthStarted) {
        return;
      } else {
        setState(() => _aguardandoGoogle = false);
      }
    } finally {
      if (mounted && !_aguardandoGoogle) {
        setState(() => _loading = false);
      }
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

  Future<void> _biometriaNaoConfigurada({bool web = false}) async {
    if (web) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometria está disponível no app Android instalado no celular.'),
          backgroundColor: verdeEscuro,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    if (!_biometriaDisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sensor biométrico ou PIN de bloqueio não disponível neste aparelho.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha e-mail e senha abaixo e toque de novo para ativar a biometria.'),
          backgroundColor: verdeEscuro,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ativar biometria'),
        content: const Text(
          'Vamos validar sua senha e o sensor do aparelho. Na próxima vez você entra só com digital ou rosto.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ativar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final bioOk = await BiometricAuthService.instance.autenticarBiometria();
      if (!bioOk || !mounted) return;
      final result = await context.read<AuthProvider>().loginEmail(email, senha);
      if (!mounted) return;
      if (!result.ok) {
        setState(() => _erro = result.message);
        return;
      }
      await BiometricAuthService.instance.habilitar(email: email, senha: senha);
      await CredentialRememberService.instance.salvar(lembrar: _lembrarSenha, email: email, senha: senha);
      await _recarregarBiometria();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometria ativada! Use o botão acima na próxima vez.'),
            backgroundColor: verdeEscuro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _linkEsqueciSenha() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _loading ? null : _esqueceuSenha,
        icon: const Icon(Icons.lock_reset, size: 20, color: verdeEscuro),
        label: const Text(
          'Esqueceu a senha?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: verdeEscuro,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _infoBiometriaWeb() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Biometria no celular'),
        content: const Text(
          'No navegador a biometria não está disponível.\n\n'
          '• Instale o app CT SM BJJ no Android e ative após o primeiro login com senha.\n'
          '• Ou marque "Lembrar e-mail e senha" abaixo para entrar mais rápido na web.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi')),
        ],
      ),
    );
  }

  Widget _chipPlataforma() {
    final label = isNativeApp ? 'App instalado' : 'Versão web';
    final cor = isNativeApp ? Colors.green.shade700 : Colors.blue.shade700;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withValues(alpha: 0.35)),
        ),
        child: Text(
          '$label · ${AppVersion.label}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cor),
        ),
      ),
    );
  }

  Widget _secaoBiometria() {
    if (!isNativeApp) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _loading ? null : _infoBiometriaWeb,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.fingerprint, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Biometria: toque aqui — disponível no app Android',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                    ),
                  ),
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading
                ? null
                : (_biometriaHabilitada ? _loginBiometrico : _biometriaNaoConfigurada),
            icon: Icon(
              Icons.fingerprint,
              size: 28,
              color: _biometriaHabilitada ? verdeEscuro : Colors.grey.shade600,
            ),
            label: Text(
              _biometriaHabilitada
                  ? 'Entrar com biometria'
                  : 'Ativar / entrar com biometria',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _biometriaHabilitada ? verdeEscuro : Colors.grey.shade700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: verdeEscuro,
              side: BorderSide(
                color: _biometriaHabilitada ? verdeEscuro : Colors.grey.shade300,
                width: _biometriaHabilitada ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (!_biometriaDisponivel)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Sensor biométrico não detectado neste aparelho.',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          Text(
                            AppVersion.short,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _chipPlataforma(),
                      _secaoBiometria(),
                      if (_erro != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_erro!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                        ),
                        const SizedBox(height: 12),
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
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _lembrarSenha,
                        onChanged: _loading
                            ? null
                            : (v) async {
                                setState(() => _lembrarSenha = v ?? false);
                                if (v != true) {
                                  await CredentialRememberService.instance.limpar();
                                }
                              },
                        title: const Text(
                          'Lembrar e-mail e senha',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Preenche automaticamente na próxima vez',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                      _linkEsqueciSenha(),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CriarContaScreen()),
                                ),
                        child: const Text(
                          'Não tem conta? Criar agora',
                          style: TextStyle(color: verdeEscuro, fontWeight: FontWeight.w600),
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
          if (_aguardandoGoogle)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: verdeEscuro),
                        const SizedBox(height: 16),
                        Text(
                          isNativeApp
                              ? 'Conclua o login Google na janela do app.\nVocê voltará automaticamente.'
                              : 'Conclua o login no navegador e volte para esta página.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() {
                            _aguardandoGoogle = false;
                            _loading = false;
                          }),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
