import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/loja/loja_publica_pending.dart';
import '../../core/supabase_errors.dart';
import '../../core/theme.dart';
import '../../models/pedido.dart';
import '../../models/produto.dart';
import '../../repositories/pedido_repository.dart';
import '../../repositories/produto_repository.dart';
import '../../utils/loja_tamanhos.dart';
import '../auth/login_screen.dart';

/// Loja acessível sem login — para vendas externas à academia.
class LojaPublicaScreen extends StatefulWidget {
  const LojaPublicaScreen({super.key});

  @override
  State<LojaPublicaScreen> createState() => _LojaPublicaScreenState();
}

class _LojaPublicaScreenState extends State<LojaPublicaScreen> {
  final _produtoRepo = ProdutoRepository();
  List<Produto> _produtos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final lista = await _produtoRepo.listar(ativo: true);
      if (mounted) setState(() {
        _produtos = lista;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _erro = mensagemErroSupabase(e, recurso: 'os produtos');
        _loading = false;
      });
    }
  }

  Future<void> _comprar(Produto p) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CompraPublicaSheet(produto: p),
    );
    if (result == null) return;

    final pedido = Pedido(
      id: '',
      alunoNome: result['nome'] as String,
      alunoEmail: result['email'] as String?,
      alunoTelefone: result['telefone'] as String?,
      produtoId: p.id,
      produtoNome: p.nome,
      varianteCor: result['cor'] as String?,
      varianteTamanho: result['tamanho'] as String?,
      quantidade: result['quantidade'] as int,
      valorUnitario: p.preco,
      valorTotal: p.preco * (result['quantidade'] as int),
      status: 'pendente',
      formaPagamento: 'pix',
      observacoes: result['observacoes'] as String?,
    );

    try {
      await PedidoRepository().criar(pedido);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pedido enviado!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Obrigado, ${result['nome']}!'),
              const SizedBox(height: 8),
              Text('Total: R\$ ${pedido.valorTotal.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              Text('Chave PIX: $pixKey', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Envie o comprovante pelo WhatsApp da academia para confirmar.'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
            FilledButton.icon(
              onPressed: () async {
                final msg = 'Olá! Fiz um pedido na loja SM BJJ: ${p.nome} — R\$ ${pedido.valorTotal.toStringAsFixed(2)}';
                final uri = Uri.parse('https://wa.me/5521975396996?text=${Uri.encodeComponent(msg)}');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.message, size: 18),
              label: const Text('WhatsApp'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErroSupabase(e, recurso: 'o pedido')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja SM BJJ'),
        actions: [
          TextButton(
            onPressed: () {
              LojaPublicaPending.desativar();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Entrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : _erro != null
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_erro!, textAlign: TextAlign.center)))
              : _produtos.isEmpty
                  ? const Center(child: Text('Nenhum produto disponível no momento.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _produtos.length,
                      itemBuilder: (_, i) {
                        final p = _produtos[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('R\$ ${p.preco.toStringAsFixed(2)} · ${p.prazoLabel}'),
                            trailing: ElevatedButton(
                              onPressed: () => _comprar(p),
                              style: ElevatedButton.styleFrom(backgroundColor: verdeEscuro, foregroundColor: Colors.white),
                              child: const Text('Comprar'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _CompraPublicaSheet extends StatefulWidget {
  final Produto produto;
  const _CompraPublicaSheet({required this.produto});

  @override
  State<_CompraPublicaSheet> createState() => _CompraPublicaSheetState();
}

class _CompraPublicaSheetState extends State<_CompraPublicaSheet> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  String? _cor;
  String? _tamanho;
  int _qtd = 1;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            Text('R\$ ${p.preco.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Seu nome *', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-mail', isDense: true), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            TextField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'WhatsApp *', isDense: true), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            if (p.categoria == 'kimono')
              DropdownButtonFormField<String>(
                value: _tamanho,
                decoration: const InputDecoration(labelText: 'Tamanho *', isDense: true),
                items: [
                  ...tamanhosKimonoInfantil.map((t) => DropdownMenuItem(value: t, child: Text('Inf. $t'))),
                  ...tamanhosKimonoAdulto.map((t) => DropdownMenuItem(value: t, child: Text('Ad. $t'))),
                ],
                onChanged: (v) => setState(() => _tamanho = v),
              )
            else
              TextField(
                decoration: const InputDecoration(labelText: 'Tamanho (opcional)', isDense: true),
                onChanged: (v) => _tamanho = v.isEmpty ? null : v,
              ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Cor (opcional)', isDense: true),
              onChanged: (v) => _cor = v.isEmpty ? null : v,
            ),
            const SizedBox(height: 8),
            TextField(controller: _obsCtrl, decoration: const InputDecoration(labelText: 'Observações', isDense: true), maxLines: 2),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_nomeCtrl.text.trim().isEmpty || _telCtrl.text.trim().isEmpty) return;
                if (p.categoria == 'kimono' && (_tamanho == null || _tamanho!.isEmpty)) return;
                Navigator.pop(context, {
                  'nome': _nomeCtrl.text.trim(),
                  'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                  'telefone': _telCtrl.text.trim(),
                  'cor': _cor,
                  'tamanho': _tamanho,
                  'quantidade': _qtd,
                  'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: verdeEscuro, foregroundColor: Colors.white),
              child: Text('Confirmar — R\$ ${(p.preco * _qtd).toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
    );
  }
}
