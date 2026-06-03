import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/mp_service.dart';

class MpConfigScreen extends StatefulWidget {
  const MpConfigScreen({super.key});
  @override
  State<MpConfigScreen> createState() => _MpConfigScreenState();
}

class _MpConfigScreenState extends State<MpConfigScreen> {
  final _tokenCtrl = TextEditingController();
  bool _loading = false;
  bool _validando = false;
  bool? _valido;
  String? _tokenSalvo;
  bool _mostrarToken = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final token = await MercadoPagoService.instance.getAccessToken();
    if (mounted) setState(() {
      _tokenSalvo = token;
      if (token != null) _tokenCtrl.text = token;
    });
  }

  Future<void> _salvar() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;

    setState(() { _validando = true; _valido = null; });
    final ok = await MercadoPagoService.instance.validarToken(token);
    setState(() { _validando = false; _valido = ok; });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Token inválido. Verifique e tente novamente.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _loading = true);
    await MercadoPagoService.instance.saveAccessToken(token);
    setState(() { _loading = false; _tokenSalvo = token; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mercado Pago configurado com sucesso!'),
        backgroundColor: verdeEscuro,
      ));
      Navigator.pop(context);
    }
  }

  Future<void> _remover() async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover configuração'),
        content: const Text('Deseja remover o token do Mercado Pago?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ));
    if (ok == true) {
      await MercadoPagoService.instance.clearAccessToken();
      setState(() { _tokenSalvo = null; _tokenCtrl.clear(); _valido = null; });
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Mercado Pago')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // Status atual
          if (_tokenSalvo != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 10),
                const Expanded(child: Text('Mercado Pago configurado e ativo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green))),
                TextButton(onPressed: _remover, child: const Text('Remover', style: TextStyle(color: Colors.red))),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(child: Text('Não configurado — cole seu Access Token abaixo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange))),
              ]),
            ),

          const SizedBox(height: 24),

          // Como obter o token
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Como obter seu Access Token', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            _passo('1', 'Acesse o painel do Mercado Pago'),
            _passo('2', 'Vá em "Sua conta" → "Configurações" → "Credenciais"'),
            _passo('3', 'Copie o "Access Token de produção"'),
            _passo('4', 'Cole abaixo e salve'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://www.mercadopago.com.br/settings/account/credentials');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_browser, size: 16),
              label: const Text('Abrir painel do Mercado Pago'),
              style: OutlinedButton.styleFrom(foregroundColor: verdeEscuro),
            ),
          ]))),

          const SizedBox(height: 20),

          // Campo token
          TextField(
            controller: _tokenCtrl,
            obscureText: !_mostrarToken,
            decoration: InputDecoration(
              labelText: 'Access Token de Produção',
              hintText: 'APP_USR-...',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                icon: Icon(_mostrarToken ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _mostrarToken = !_mostrarToken),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              helperText: 'Começa com APP_USR- (produção) ou TEST- (testes)',
            ),
            onChanged: (_) => setState(() => _valido = null),
          ),

          if (_valido == false) ...[
            const SizedBox(height: 8),
            const Text('❌ Token inválido — verifique se copiou corretamente',
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_valido == true) ...[
            const SizedBox(height: 8),
            const Text('✅ Token válido!', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
          ],

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: (_loading || _validando) ? null : _salvar,
            icon: (_loading || _validando)
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_validando ? 'Validando...' : 'Salvar e Ativar'),
          ),

          const SizedBox(height: 24),

          // Info sobre o que é possível
          Card(color: verdeEscuro.withValues(alpha: 0.05), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('O que você poderá fazer:', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _item('Gerar link de cobrança de mensalidade'),
            _item('Cobranças avulsas (loja, eventos, taxas)'),
            _item('Compartilhar link via WhatsApp'),
            _item('PIX, cartão de crédito e boleto'),
            _item('Os alunos pagam pelo link sem instalar nada'),
          ]))),
        ]),
      ),
    );
  }

  Widget _passo(String num, String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      CircleAvatar(radius: 11, backgroundColor: verdeEscuro, child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
      const SizedBox(width: 8),
      Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
    ]),
  );

  Widget _item(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      const Icon(Icons.check, color: verdeEscuro, size: 16),
      const SizedBox(width: 6),
      Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
    ]),
  );
}
