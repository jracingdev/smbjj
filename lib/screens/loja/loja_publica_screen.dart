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
import '../../widgets/produto_imagem.dart';
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
  String _filtroCategoria = 'todos';

  static const _categorias = ['kimono', 'faixa', 'camisa', 'short', 'outro'];
  static const _catLabel = {
    'kimono': 'Kimono',
    'faixa': 'Faixa',
    'camisa': 'Camisa',
    'short': 'Short',
    'outro': 'Outro',
  };
  static const _catColor = {
    'kimono': Colors.blue,
    'faixa': Colors.amber,
    'camisa': Colors.purple,
    'short': Colors.orange,
    'outro': Colors.grey,
  };

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
      if (mounted) {
        setState(() {
          _produtos = lista;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = mensagemErroSupabase(e, recurso: 'os produtos');
          _loading = false;
        });
      }
    }
  }

  List<Produto> get _filtrados => _produtos
      .where((p) => _filtroCategoria == 'todos' || p.categoria == _filtroCategoria)
      .toList();

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    return 2;
  }

  Future<void> _comprar(Produto p) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Expanded(child: Text('Pedido enviado!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Obrigado, ${result['nome']}!'),
              const SizedBox(height: 8),
              Text(
                'Total: R\$ ${pedido.valorTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: verdeEscuro),
              ),
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
                final msg =
                    'Olá! Fiz um pedido na loja SM BJJ: ${p.nome} — R\$ ${pedido.valorTotal.toStringAsFixed(2)}';
                final uri = Uri.parse(
                  'https://wa.me/$professorTelefone?text=${Uri.encodeComponent(msg)}',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.message, size: 18),
              label: const Text('WhatsApp'),
              style: FilledButton.styleFrom(backgroundColor: verdeEscuro),
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

  void _entrar() {
    LojaPublicaPending.desativar();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: RefreshIndicator(
        color: verdeEscuro,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              backgroundColor: verdeEscuro,
              actions: [
                TextButton.icon(
                  onPressed: _entrar,
                  icon: const Icon(Icons.login, color: Colors.white, size: 18),
                  label: const Text('Entrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [verdeEscuro, Color(0xFF145521)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 36),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(Icons.sports_martial_arts, size: 40, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Loja SM BJJ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          academiaCredenciada,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_loading && _erro == null && _produtos.isNotEmpty)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      _FiltroChip(
                        label: 'Todos',
                        selected: _filtroCategoria == 'todos',
                        onTap: () => setState(() => _filtroCategoria = 'todos'),
                      ),
                      ..._categorias.map(
                        (c) => _FiltroChip(
                          label: _catLabel[c]!,
                          selected: _filtroCategoria == c,
                          onTap: () => setState(() => _filtroCategoria = c),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: verdeEscuro)),
              )
            else if (_erro != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                ),
              )
            else if (_filtrados.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _produtos.isEmpty
                            ? 'Nenhum produto disponível no momento.'
                            : 'Nenhum produto nesta categoria.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount(context),
                    childAspectRatio: 0.54,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = _filtrados[i];
                      return _ProdutoPublicoCard(
                        produto: p,
                        catLabel: _catLabel[p.categoria] ?? p.categoria,
                        catColor: _catColor[p.categoria] ?? Colors.grey,
                        onComprar: () => _comprar(p),
                      );
                    },
                    childCount: _filtrados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: verdeEscuro.withValues(alpha: 0.15),
        checkmarkColor: verdeEscuro,
        labelStyle: TextStyle(
          color: selected ? verdeEscuro : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ProdutoPublicoCard extends StatelessWidget {
  final Produto produto;
  final String catLabel;
  final Color catColor;
  final VoidCallback onComprar;

  const _ProdutoPublicoCard({
    required this.produto,
    required this.catLabel,
    required this.catColor,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onComprar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: ProdutoImagem(
                fotoUrl: produto.fotoUrl,
                youtubeThumb: produto.youtubeThumbnail,
                priorizarVideo: produto.temVideoYouTube,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      produto.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Chip(
                          label: Text(catLabel, style: const TextStyle(fontSize: 10)),
                          backgroundColor: catColor.withValues(alpha: 0.15),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        Text(
                          'R\$ ${produto.preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: verdeEscuro,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            produto.prazoLabel,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onComprar,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                      label: const Text('Comprar', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: verdeEscuro,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 140,
                child: ProdutoImagem(
                  fotoUrl: p.fotoUrl,
                  youtubeThumb: p.youtubeThumbnail,
                  priorizarVideo: p.temVideoYouTube,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(p.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(
              'R\$ ${p.preco.toStringAsFixed(2)} / unidade',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (p.descricao != null && p.descricao!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(p.descricao!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 16),
            const Text('Seus dados', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Seu nome *', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'E-mail', isDense: true),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _telCtrl,
              decoration: const InputDecoration(labelText: 'WhatsApp *', isDense: true),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const Text('Produto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantidade:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _qtd > 1 ? () => setState(() => _qtd--) : null,
                    ),
                    Text('$_qtd', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: verdeEscuro),
                      onPressed: () => setState(() => _qtd++),
                    ),
                  ],
                ),
              ],
            ),
            TextField(
              controller: _obsCtrl,
              decoration: const InputDecoration(labelText: 'Observações', isDense: true),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: verdeEscuro.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    'R\$ ${(p.preco * _qtd).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: verdeEscuro),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_nomeCtrl.text.trim().isEmpty || _telCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha nome e WhatsApp.')),
                  );
                  return;
                }
                if (p.categoria == 'kimono' && (_tamanho == null || _tamanho!.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione o tamanho do kimono.')),
                  );
                  return;
                }
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
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Confirmar — R\$ ${(p.preco * _qtd).toStringAsFixed(2)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: verdeEscuro,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
