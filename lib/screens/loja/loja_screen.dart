import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/loja/loja_publica_url.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/mp_service.dart';
import '../../core/theme.dart';
import '../../models/pedido.dart';
import '../../models/produto.dart';
import '../../core/storage_service.dart';
import '../../core/supabase_errors.dart';
import '../../repositories/pedido_repository.dart';
import '../../repositories/produto_repository.dart';
import '../../repositories/variante_repository.dart';
import '../../models/produto_variante.dart';
import '../../utils/date_utils.dart';
import '../../utils/loja_tamanhos.dart';
import 'pedidos_admin_screen.dart';
import 'meus_pedidos_screen.dart';

class LojaScreen extends StatefulWidget {
  /// Só carrega produtos quando a aba Loja está visível (mais rápido no app).
  final bool tabAtiva;
  const LojaScreen({super.key, this.tabAtiva = false});
  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  final _repo = ProdutoRepository();
  final _varianteRepo = VarianteRepository();
  List<Produto> _produtos = [];
  Map<String, List<ProdutoVariante>> _variantesPorProduto = {};
  bool _loading = false;
  bool _carregou = false;
  String? _erroLoad;
  String _filtroCategoria = 'todos';
  static const _categorias = ['kimono', 'faixa', 'camisa', 'short', 'outro'];
  static const _catLabel = {'kimono':'Kimono','faixa':'Faixa','camisa':'Camisa','short':'Short','outro':'Outro'};
  static const _catColor = {
    'kimono': Colors.blue, 'faixa': Colors.amber, 'camisa': Colors.purple,
    'short': Colors.orange, 'outro': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    if (widget.tabAtiva) _iniciarCarga();
  }

  @override
  void didUpdateWidget(LojaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabAtiva && !_carregou) _iniciarCarga();
  }

  void _iniciarCarga() {
    _carregou = true;
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _erroLoad = null;
    });
    try {
      final isAdmin = context.read<AuthProvider>().isAdmin;
      final lista = await _repo.listar(ativo: isAdmin ? null : true);
      final variantes = await _varianteRepo.porProdutos(lista.map((p) => p.id).toList());
      if (!mounted) return;
      setState(() {
        _produtos = lista;
        _variantesPorProduto = variantes;
        _loading = false;
      });
      if (isAdmin) {
        final fotosQuebradas = lista.where((p) {
          final u = p.fotoUrl;
          return u != null && u.isNotEmpty && !u.startsWith('http');
        }).length;
        if (fotosQuebradas > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$fotosQuebradas produto(s) com foto antiga. Edite e salve de novo para enviar ao Supabase.',
              ),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _produtos = [];
          _loading = false;
          _erroLoad = mensagemErroSupabase(e, recurso: 'os produtos');
        });
      }
    }
  }

  List<Produto> get _filtrados => _produtos.where((p) => _filtroCategoria == 'todos' || p.categoria == _filtroCategoria).toList();

  double _aspectRatioAdmin(List<Produto> produtos) {
    var maxGrade = 0;
    for (final p in produtos) {
      final n = (_variantesPorProduto[p.id] ?? const []).length;
      if (n > maxGrade) maxGrade = n;
    }
    if (maxGrade == 0) return 1.35;
    if (maxGrade <= 4) return 1.05;
    if (maxGrade <= 8) return 0.88;
    return 0.75;
  }

  Future<void> _deletar(Produto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(content: Text('Remover ${p.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ]),
    );
    if (ok == true) { await _repo.deletar(p.id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja SM BJJ'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Link público da loja',
              onPressed: () async {
                final link = urlLojaPublica();
                await Clipboard.setData(ClipboardData(text: link));
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Loja pública'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Compartilhe este link para vender para quem não é aluno:'),
                        const SizedBox(height: 10),
                        SelectableText(link, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
                      FilledButton.icon(
                        onPressed: () {
                          Share.share('Loja SM BJJ — compre kimonos e produtos:\n$link');
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Compartilhar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(isAdmin ? Icons.list_alt : Icons.receipt_long_outlined),
            tooltip: isAdmin ? 'Pedidos' : 'Meus Pedidos',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => isAdmin ? const PedidosAdminScreen() : const MeusPedidosScreen(),
            )),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _ProdutoSheet(onSaved: _load),
          );
        },
        backgroundColor: verdeEscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Produto', style: TextStyle(color: Colors.white)),
      ) : null,
      body: Column(children: [
        // Filtros
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _FiltroChip(label: 'Todos', selected: _filtroCategoria == 'todos', onTap: () => setState(() => _filtroCategoria = 'todos')),
            ..._categorias.map((c) => _FiltroChip(label: _catLabel[c]!, selected: _filtroCategoria == c, onTap: () => setState(() => _filtroCategoria = c))),
          ]),
        ),
        Expanded(
          child: !_carregou
              ? Center(
                  child: Text(
                    'Carregando loja…',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : _loading
              ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
              : _erroLoad != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_erroLoad!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
                          ],
                        ),
                      ),
                    )
              : _filtrados.isEmpty
                  ? Center(child: Text('Nenhum produto encontrado.', style: TextStyle(color: Colors.grey.shade500)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isAdmin ? 1 : 2,
                        childAspectRatio: isAdmin ? _aspectRatioAdmin(_filtrados) : 0.54,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) {
                        final p = _filtrados[i];
                        final variantes = _variantesPorProduto[p.id] ?? const <ProdutoVariante>[];
                        return _ProdutoCard(
                          produto: p,
                          variantes: variantes,
                          catLabel: _catLabel[p.categoria] ?? p.categoria,
                          catColor: _catColor[p.categoria] ?? Colors.grey,
                          isAdmin: isAdmin,
                          onEdit: isAdmin ? () async {
                            await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (_) => _ProdutoSheet(produto: p, onSaved: _load),
                            );
                          } : null,
                          onDelete: isAdmin ? () => _deletar(p) : null,
                          onSolicitar: !isAdmin ? () async {
                            // Cria pedido e notifica professor
                            await _criarPedido(context, p);
                          } : null,
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  Future<void> _criarPedido(BuildContext ctx, Produto p) async {
    final auth = ctx.read<AuthProvider>();
    final user = auth.usuario;
    if (user == null) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: ctx, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SolicitarSheet(produto: p),
    );
    if (result == null) return;

    final cor = result['cor'] as String?;
    final tamanho = result['tamanho'] as String?;
    final qtd = result['quantidade'] as int;
    final obs = result['observacoes'] as String?;
    final forma = result['forma_pagamento'] as String? ?? 'pix';
    final total = p.preco * qtd;

    final aluno = auth.alunoVinculado;
    final telefone = aluno?.telefone?.trim();

    final pedido = Pedido(
      id: '',
      alunoId: aluno?.id,
      alunoNome: user.nome,
      alunoEmail: user.email,
      alunoTelefone: telefone?.isNotEmpty == true ? telefone : null,
      produtoId: p.id,
      produtoNome: p.nome,
      varianteCor: cor,
      varianteTamanho: tamanho,
      quantidade: qtd,
      valorUnitario: p.preco,
      valorTotal: total,
      status: 'pendente',
      formaPagamento: forma,
      observacoes: obs,
    );

    final repo = PedidoRepository();
    Pedido criado;
    try {
      criado = await repo.criar(pedido);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(mensagemErroSupabase(e, recurso: 'o pedido')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!ctx.mounted) return;

    if (forma == 'mercadopago') {
      final pref = await MercadoPagoService.instance.criarCobranca(
        titulo: 'Pedido ${p.nome} - SM BJJ',
        valor: total,
        emailPagador: user.email,
        descricao: '${p.nome}${cor != null || tamanho != null ? ' (${[if (cor != null) cor, if (tamanho != null) tamanho].join(' / ')})' : ''} — Qtd: $qtd',
      );
      if (!ctx.mounted) return;
      if (pref == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Mercado Pago não configurado. Peça ao professor ou pague via PIX em Meus Pedidos.'),
          backgroundColor: Colors.orange,
        ));
      } else {
        await repo.atualizarLinkPagamento(criado.id, pref.link);
        if (!ctx.mounted) return;
        final linkUri = Uri.parse(pref.link);
        if (await canLaunchUrl(linkUri)) {
          await launchUrl(
            linkUri,
            mode: kIsWeb ? LaunchMode.externalApplication : LaunchMode.inAppWebView,
          );
        }
      }
    } else if (forma == 'pix') {
      if (!ctx.mounted) return;
      await _mostrarDialogPix(ctx, valor: total, produtoNome: p.nome);
    }

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Pedido registrado! Acompanhe em "Meus Pedidos".'),
        backgroundColor: verdeEscuro,
      ));
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const MeusPedidosScreen()));
    }
  }

  Future<void> _mostrarDialogPix(BuildContext ctx, {required double valor, required String produtoNome}) async {
    await showDialog<void>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Pagamento PIX'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(produtoNome, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Valor: R\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: verdeEscuro)),
          const SizedBox(height: 12),
          Text('Favorecido: $pixNome', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const SizedBox(height: 8),
          SelectableText(pixKey, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          Text('Copie a chave PIX, pague o valor acima e envie o comprovante ao professor pelo WhatsApp. O pedido será confirmado após a validação.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Fechar')),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: pixKey));
              ScaffoldMessenger.of(dctx).showSnackBar(const SnackBar(content: Text('Chave PIX copiada!')));
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar chave PIX'),
            style: FilledButton.styleFrom(backgroundColor: verdeEscuro),
          ),
        ],
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
        selectedColor: verdeEscuro.withOpacity(0.15),
        checkmarkColor: verdeEscuro,
        labelStyle: TextStyle(color: selected ? verdeEscuro : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}

// ── Sheet de solicitação com variante e quantidade ───────────
class _SolicitarSheet extends StatefulWidget {
  final Produto produto;
  const _SolicitarSheet({required this.produto});
  @override
  State<_SolicitarSheet> createState() => _SolicitarSheetState();
}

class _SolicitarSheetState extends State<_SolicitarSheet> {
  String? _cor, _tamanho;
  int _qtd = 1;
  String _formaPagamento = 'pix';
  bool _mpDisponivel = false;
  final _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    MercadoPagoService.instance.getAccessToken().then((t) {
      if (mounted) setState(() => _mpDisponivel = t != null && t.isNotEmpty);
    });
  }

  @override
  void dispose() { _obsCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Solicitar: ${p.nome}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        Text('R\$ ${p.preco.toStringAsFixed(2)} / unidade', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 140,
            child: _ProdutoImagem(fotoUrl: p.fotoUrl, youtubeThumb: p.youtubeThumbnail, priorizarVideo: p.temVideoYouTube),
          ),
        ),
        const SizedBox(height: 16),

        // Cor
        const Text('Cor (opcional):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(onChanged: (v) => setState(() => _cor = v.isEmpty ? null : v),
          decoration: const InputDecoration(hintText: 'Ex: Branco, Azul, Preto...', isDense: true)),
        const SizedBox(height: 12),

        // Tamanho
        Text(
          p.categoria == 'kimono' ? 'Tamanho (obrigatório):' : 'Tamanho (opcional):',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        if (p.categoria == 'kimono') ...[
          DropdownButtonFormField<String>(
            value: _tamanho,
            decoration: const InputDecoration(hintText: 'Selecione o tamanho', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ...tamanhosKimonoInfantil.map((t) => DropdownMenuItem(value: t, child: Text('Infantil $t'))),
              ...tamanhosKimonoAdulto.map((t) => DropdownMenuItem(value: t, child: Text('Adulto $t'))),
            ],
            onChanged: (v) => setState(() => _tamanho = v),
          ),
        ] else
          TextField(
            onChanged: (v) => setState(() => _tamanho = v.isEmpty ? null : v),
            decoration: const InputDecoration(hintText: 'Ex: P, M, G...', isDense: true),
          ),
        const SizedBox(height: 12),

        // Quantidade
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Quantidade:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _qtd > 1 ? () => setState(() => _qtd--) : null),
            Text('$_qtd', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: verdeEscuro), onPressed: () => setState(() => _qtd++)),
          ]),
        ]),

        // Total
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total do pedido:', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('R\$ ${(p.preco * _qtd).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: verdeEscuro)),
          ])),
        const SizedBox(height: 12),

        // Observações
        TextField(controller: _obsCtrl,
          decoration: const InputDecoration(labelText: 'Observações (opcional)', isDense: true),
          maxLines: 2),
        const SizedBox(height: 16),

        const Text('Forma de pagamento', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        RadioListTile<String>(
          value: 'pix',
          groupValue: _formaPagamento,
          onChanged: (v) => setState(() => _formaPagamento = v!),
          title: const Text('PIX à vista'),
          subtitle: Text('Chave: $pixKey', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          secondary: const Icon(Icons.pix, color: verdeEscuro),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String>(
          value: 'mercadopago',
          groupValue: _formaPagamento,
          onChanged: _mpDisponivel ? (v) => setState(() => _formaPagamento = v!) : null,
          title: const Text('Mercado Pago'),
          subtitle: Text(
            _mpDisponivel ? 'PIX, cartão e boleto pelo link' : 'Indisponível — professor deve configurar no app',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          secondary: Icon(Icons.payment, color: _mpDisponivel ? Colors.blue : Colors.grey),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: p.categoria == 'kimono' && (_tamanho == null || _tamanho!.isEmpty)
              ? null
              : () => Navigator.pop(context, {
                    'cor': _cor,
                    'tamanho': _tamanho,
                    'quantidade': _qtd,
                    'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
                    'forma_pagamento': _formaPagamento,
                  }),
          icon: const Icon(Icons.shopping_cart_checkout),
          label: Text('Confirmar pedido — R\$ ${(p.preco * _qtd).toStringAsFixed(2)}'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
        ),
      ])),
    );
  }
}

class _ProdutoCard extends StatelessWidget {
  final Produto produto;
  final List<ProdutoVariante> variantes;
  final String catLabel;
  final Color catColor;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSolicitar;
  const _ProdutoCard({
    required this.produto,
    this.variantes = const [],
    required this.catLabel,
    required this.catColor,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
    this.onSolicitar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Opacity(
        opacity: produto.ativo ? 1.0 : 0.55,
        child: InkWell(
          onTap: !isAdmin ? onSolicitar : null,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: isAdmin ? 2.4 : 1.2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProdutoImagem(
                    fotoUrl: produto.fotoUrl,
                    youtubeThumb: produto.youtubeThumbnail,
                    priorizarVideo: produto.temVideoYouTube,
                  ),
                  if (isAdmin && !produto.ativo)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Inativo', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (isAdmin)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        children: [
                          _CardActionButton(icon: Icons.edit_outlined, color: verdeEscuro, onTap: onEdit),
                          const SizedBox(width: 4),
                          _CardActionButton(icon: Icons.delete_outline, color: Colors.red, onTap: onDelete),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
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
                        backgroundColor: catColor.withOpacity(0.15),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      Text(
                        'R\$ ${produto.preco.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: verdeEscuro),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(produto.prazoLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  if (isAdmin && variantes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Grade (${variantes.length})',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...variantes.take(12).map(
                          (v) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: verdeEscuro.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: verdeEscuro.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '${v.label.isNotEmpty ? v.label : '—'} · est. ${v.estoque}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        if (variantes.length > 12)
                          Text(
                            '+${variantes.length - 12}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ] else if (isAdmin) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Sem grade cadastrada',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (!isAdmin) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: onSolicitar,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                      label: const Text('Comprar', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _CardActionButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  const _PlaceholderImg();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey.shade100,
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 6),
        Text('Sem foto', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    ),
  );
}

class _ProdutoImagem extends StatelessWidget {
  final String? fotoUrl;
  final String? youtubeThumb;
  final bool priorizarVideo;
  const _ProdutoImagem({this.fotoUrl, this.youtubeThumb, this.priorizarVideo = false});

  @override
  Widget build(BuildContext context) {
    if (priorizarVideo && youtubeThumb != null) {
      return _youtubeThumbWidget(youtubeThumb!);
    }

    final path = fotoUrl?.isNotEmpty == true ? fotoUrl : null;
    // URL de foto que na verdade é link do YouTube
    if (path != null && Produto.youtubeVideoIdFromUrl(path) != null) {
      final thumb = 'https://img.youtube.com/vi/${Produto.youtubeVideoIdFromUrl(path)}/mqdefault.jpg';
      return _youtubeThumbWidget(thumb);
    }

    if (path != null) {
      final remote = path.startsWith('http://') || path.startsWith('https://');
      if (remote) {
        return Container(
          color: Colors.grey.shade100,
          width: double.infinity,
          height: double.infinity,
          child: Image.network(
            path,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _fallbackYoutube(youtubeThumb),
          ),
        );
      }
      return Container(
        color: Colors.grey.shade100,
        width: double.infinity,
        height: double.infinity,
        child: imageWidgetFromPath(
          path,
          fit: BoxFit.contain,
          errorWidget: _fallbackYoutube(youtubeThumb),
        ),
      );
    }

    return _fallbackYoutube(youtubeThumb);
  }

  Widget _youtubeThumbWidget(String thumb) => Stack(fit: StackFit.expand, children: [
    Container(
      color: Colors.grey.shade100,
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        thumb,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _PlaceholderImg(),
      ),
    ),
    const Center(child: Icon(Icons.play_circle_filled, color: Colors.white, size: 40)),
  ]);

  Widget _fallbackYoutube(String? thumb) {
    if (thumb != null) return _youtubeThumbWidget(thumb);
    return const _PlaceholderImg();
  }
}

class _ProdutoSheet extends StatefulWidget {
  final Produto? produto;
  final VoidCallback onSaved;
  const _ProdutoSheet({this.produto, required this.onSaved});
  @override
  State<_ProdutoSheet> createState() => _ProdutoSheetState();
}

class _ProdutoSheetState extends State<_ProdutoSheet> {
  final _repo = ProdutoRepository();
  final _varianteRepo = VarianteRepository();
  final _uuid = const Uuid();
  late final _nomeCtrl = TextEditingController();
  late final _precoCtrl = TextEditingController();
  late final _descCtrl = TextEditingController();
  late final _youtubeCtrl = TextEditingController();
  late final _prazoDiasCtrl = TextEditingController();
  late final _prazoDataCtrl = TextEditingController();
  String _categoria = 'kimono';
  String _prazoEntrega = 'imediato';
  bool _ativo = true;
  bool _loading = false;
  String? _fotoUrl;
  Uint8List? _fotoBytes;
  String _fotoExt = 'jpg';

  // Grade de variantes: lista de {cor, tamanho, estoque}
  final List<Map<String, dynamic>> _variantes = [];

  // Cores e tamanhos comuns para sugestão
  static const _coresSugeridas = ['Branco', 'Preto', 'Azul', 'Verde', 'Cinza', 'Vermelho', 'Amarelo'];
  List<String> get _tamanhosSugeridos => tamanhosSugeridosProduto(_categoria);

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    if (p != null) {
      _nomeCtrl.text = p.nome;
      _precoCtrl.text = p.preco.toStringAsFixed(2);
      _descCtrl.text = p.descricao ?? '';
      _youtubeCtrl.text = p.youtubeUrl ?? '';
      _prazoDiasCtrl.text = p.prazoDias.toString();
      _prazoDataCtrl.text = p.prazoData != null ? formatDataBr(p.prazoData) : '';
      _categoria = p.categoria;
      _prazoEntrega = p.prazoEntrega;
      _ativo = p.ativo;
      _fotoUrl = p.fotoUrl;
      _carregarVariantes(p.id);
    }
  }

  Future<void> _carregarVariantes(String produtoId) async {
    try {
      final lista = await _varianteRepo.porProduto(produtoId);
      if (!mounted) return;
      setState(() {
        _variantes
          ..clear()
          ..addAll(lista.map((v) => {
                'cor': v.cor ?? '',
                'tamanho': v.tamanho ?? '',
                'estoque': v.estoque,
              }));
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nomeCtrl.dispose(); _precoCtrl.dispose(); _descCtrl.dispose();
    _youtubeCtrl.dispose(); _prazoDiasCtrl.dispose(); _prazoDataCtrl.dispose();
    super.dispose();
  }

  void _addVariante() {
    setState(() => _variantes.add({'cor': '', 'tamanho': '', 'estoque': 0}));
  }

  void _removeVariante(int i) => setState(() => _variantes.removeAt(i));

  static bool _isUrlRemota(String? url) =>
      url != null && (url.startsWith('http://') || url.startsWith('https://'));

  String? _fotoRemotaExistente() {
    final atual = widget.produto?.fotoUrl;
    return _isUrlRemota(atual) ? atual : null;
  }

  Future<void> _pickFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Foto do produto', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tirar foto agora'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, imageQuality: 80);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    final nome = img.name.toLowerCase();
    var ext = 'jpg';
    if (nome.endsWith('.png')) ext = 'png';
    if (nome.endsWith('.webp')) ext = 'webp';
    setState(() {
      _fotoBytes = bytes;
      _fotoExt = ext;
      _fotoUrl = kIsWeb ? null : img.path;
    });
  }

  Widget _previewFoto() {
    if (_fotoBytes != null) {
      return Image.memory(_fotoBytes!, fit: BoxFit.cover);
    }
    if (_isUrlRemota(_fotoUrl)) {
      return imageWidgetFromPath(_fotoUrl!, fit: BoxFit.cover);
    }
    if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            kIsWeb
                ? 'Foto antiga (apenas no celular). Escolha uma imagem abaixo.'
                : 'Carregando preview…',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
          ),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey),
        Text('Toque para adicionar foto', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    String? fotoFinal;
    if (_fotoBytes != null) {
      fotoFinal = await uploadFotoBucket(
        pasta: 'produtos',
        bytes: _fotoBytes,
        extension: _fotoExt,
        urlAtual: _fotoRemotaExistente(),
      );
      if (fotoFinal == null && mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Falha ao enviar a foto. Confira login, bucket "fotos" e políticas no Supabase.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_isUrlRemota(_fotoUrl)) {
      fotoFinal = _fotoUrl;
    } else if (!kIsWeb && _fotoUrl != null && _fotoUrl!.isNotEmpty) {
      fotoFinal = await uploadFotoBucket(
        pasta: 'produtos',
        localPath: _fotoUrl,
        urlAtual: _fotoRemotaExistente(),
      );
      if (fotoFinal == null && mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao enviar a foto. Verifique conexão e permissões no Supabase.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      fotoFinal = _fotoRemotaExistente();
    }

    final p = Produto(
      id: widget.produto?.id ?? _uuid.v4(),
      nome: _nomeCtrl.text.trim(),
      categoria: _categoria,
      descricao: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      preco: double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0,
      fotoUrl: fotoFinal,
      youtubeUrl: _youtubeCtrl.text.trim().isEmpty ? null : _youtubeCtrl.text.trim(),
      prazoEntrega: _prazoEntrega,
      prazoDias: int.tryParse(_prazoDiasCtrl.text) ?? 0,
      prazoData: () {
        final t = _prazoDataCtrl.text.trim();
        if (t.isEmpty) return null;
        return dataCompletaParaIso(t) ?? t;
      }(),
      ativo: _ativo,
      createdAt: widget.produto?.createdAt,
    );
    try {
      final Produto salvo;
      if (widget.produto != null) {
        await _repo.atualizar(p);
        salvo = p;
      } else {
        salvo = await _repo.criar(p);
      }

      final variantes = _variantes
          .where((v) {
            final cor = (v['cor'] as String? ?? '').trim();
            final tam = (v['tamanho'] as String? ?? '').trim();
            return cor.isNotEmpty || tam.isNotEmpty;
          })
          .map(
            (v) => ProdutoVariante(
              id: _uuid.v4(),
              produtoId: salvo.id,
              cor: () {
                final c = (v['cor'] as String? ?? '').trim();
                return c.isEmpty ? null : c;
              }(),
              tamanho: () {
                final t = (v['tamanho'] as String? ?? '').trim();
                return t.isEmpty ? null : t;
              }(),
              estoque: v['estoque'] as int? ?? 0,
            ),
          )
          .toList();
      await _varianteRepo.sincronizar(salvo.id, variantes);

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErroSupabase(e, recurso: 'o produto')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    final thumb = Produto(id:'',nome:'',preco:0,youtubeUrl: _youtubeCtrl.text).youtubeThumbnail;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.produto != null ? 'Editar Produto' : 'Novo Produto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),

        // Foto
        GestureDetector(
          onTap: _pickFoto,
          child: Container(
            height: 120, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)),
            clipBehavior: Clip.antiAlias,
            child: Stack(fit: StackFit.expand, children: [
              _previewFoto(),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Nome e categoria
        TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome *', isDense: true)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _categoria,
            decoration: const InputDecoration(labelText: 'Categoria', isDense: true),
            items: const [
              DropdownMenuItem(value: 'kimono', child: Text('Kimono')),
              DropdownMenuItem(value: 'faixa', child: Text('Faixa')),
              DropdownMenuItem(value: 'camisa', child: Text('Camisa')),
              DropdownMenuItem(value: 'short', child: Text('Short')),
              DropdownMenuItem(value: 'outro', child: Text('Outro')),
            ],
            onChanged: (v) => setState(() => _categoria = v!),
          )),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _precoCtrl,
            decoration: const InputDecoration(labelText: 'Preço (R\$)', isDense: true),
            keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descrição', isDense: true), maxLines: 2),
        const SizedBox(height: 16),

        // Grade de variantes
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Grade (Cor / Tamanho / Estoque)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          TextButton.icon(onPressed: _addVariante, icon: const Icon(Icons.add, size: 16), label: const Text('Adicionar')),
        ]),
        if (_variantes.isEmpty)
          Text('Nenhuma variante — produto sem grade', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ..._variantes.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Autocomplete<String>(
                optionsBuilder: (t) => _coresSugeridas.where((c) => c.toLowerCase().contains(t.text.toLowerCase())),
                onSelected: (s) => setState(() => _variantes[i]['cor'] = s),
                fieldViewBuilder: (_, ctrl, focus, __) {
                  ctrl.text = v['cor'] ?? '';
                  return TextField(controller: ctrl, focusNode: focus,
                    onChanged: (s) => _variantes[i]['cor'] = s,
                    decoration: const InputDecoration(labelText: 'Cor', isDense: true));
                },
              )),
              const SizedBox(width: 6),
              Expanded(child: Autocomplete<String>(
                optionsBuilder: (t) => _tamanhosSugeridos.where((s) => s.toLowerCase().contains(t.text.toLowerCase())),
                onSelected: (s) => setState(() => _variantes[i]['tamanho'] = s),
                fieldViewBuilder: (_, ctrl, focus, __) {
                  ctrl.text = v['tamanho'] ?? '';
                  return TextField(controller: ctrl, focusNode: focus,
                    onChanged: (s) => _variantes[i]['tamanho'] = s,
                    decoration: const InputDecoration(labelText: 'Tam', isDense: true));
                },
              )),
              const SizedBox(width: 6),
              SizedBox(width: 60, child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qtd', isDense: true),
                onChanged: (s) => _variantes[i]['estoque'] = int.tryParse(s) ?? 0,
                controller: TextEditingController(text: v['estoque'].toString()),
              )),
              IconButton(onPressed: () => _removeVariante(i),
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
          );
        }),
        const SizedBox(height: 16),

        // YouTube
        TextField(
          controller: _youtubeCtrl,
          decoration: const InputDecoration(labelText: 'Link YouTube (opcional)', hintText: 'https://youtube.com/watch?v=...', isDense: true, prefixIcon: Icon(Icons.play_circle_outline)),
          onChanged: (_) => setState(() {}),
        ),
        if (thumb != null) ...[
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(thumb, height: 100, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox())),
        ],
        const SizedBox(height: 16),

        // Prazo de entrega
        const Text('Prazo de Entrega', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'imediato', label: Text('Imediato'), icon: Icon(Icons.store, size: 14)),
            ButtonSegment(value: 'dias', label: Text('Em dias'), icon: Icon(Icons.schedule, size: 14)),
            ButtonSegment(value: 'data', label: Text('Data certa'), icon: Icon(Icons.event, size: 14)),
          ],
          selected: {_prazoEntrega},
          onSelectionChanged: (s) => setState(() => _prazoEntrega = s.first),
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        if (_prazoEntrega == 'dias') ...[
          const SizedBox(height: 8),
          TextField(controller: _prazoDiasCtrl,
            decoration: const InputDecoration(labelText: 'Quantos dias?', isDense: true),
            keyboardType: TextInputType.number),
        ],
        if (_prazoEntrega == 'data') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _prazoDataCtrl,
            decoration: InputDecoration(labelText: 'Data de entrega ($hintDataCompleta)', isDense: true),
            inputFormatters: [DataNascimentoInputFormatter()],
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 10),
        SwitchListTile(title: const Text('Produto ativo'), value: _ativo,
          onChanged: (v) => setState(() => _ativo = v),
          activeColor: verdeEscuro, contentPadding: EdgeInsets.zero),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _salvar,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.produto != null ? 'Salvar Alterações' : 'Criar Produto'),
        ),
      ])),
    );
  }
}




