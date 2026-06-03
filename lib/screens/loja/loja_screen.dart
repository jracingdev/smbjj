import 'package:flutter/material.dart';
import '../../utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/pedido.dart';
import '../../models/produto.dart';
import '../../repositories/pedido_repository.dart';
import '../../repositories/produto_repository.dart';
import 'pedidos_admin_screen.dart';
import 'meus_pedidos_screen.dart';

class LojaScreen extends StatefulWidget {
  const LojaScreen({super.key});
  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  final _repo = ProdutoRepository();
  List<Produto> _produtos = [];
  bool _loading = true;
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
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final lista = await _repo.listar(ativo: isAdmin ? null : true);
    if (mounted) setState(() { _produtos = lista; _loading = false; });
  }

  List<Produto> get _filtrados => _produtos.where((p) => _filtroCategoria == 'todos' || p.categoria == _filtroCategoria).toList();

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
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
              : _filtrados.isEmpty
                  ? Center(child: Text('Nenhum produto encontrado.', style: TextStyle(color: Colors.grey.shade500)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) {
                        final p = _filtrados[i];
                        return _ProdutoCard(
                          produto: p,
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
    final user = ctx.read<AuthProvider>().usuario;
    if (user == null) return;

    // Selecionar variante se houver
    String? cor, tamanho;
    // Sheet de seleção de variante + quantidade
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: ctx, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SolicitarSheet(produto: p),
    );
    if (result == null) return;

    cor = result['cor'];
    tamanho = result['tamanho'];
    final qtd = result['quantidade'] as int;
    final obs = result['observacoes'] as String?;

    final pedido = Pedido(
      id: '',
      alunoNome: user.nome,
      alunoEmail: user.email,
      alunoTelefone: result['telefone'],
      produtoId: p.id,
      produtoNome: p.nome,
      varianteCor: cor,
      varianteTamanho: tamanho,
      quantidade: qtd,
      valorUnitario: p.preco,
      valorTotal: p.preco * qtd,
      status: 'pendente',
      observacoes: obs,
    );

    await PedidoRepository().criar(pedido);

    // Notifica professor via WhatsApp
    const professorTel = '5521975396996';
    final msg = '🛒 Novo pedido na Loja SM BJJ!\n\n'
        'Aluno: *${user.nome}*\n'
        'Produto: *${p.nome}*\n'
        '${cor != null ? 'Cor: $cor\n' : ''}'
        '${tamanho != null ? 'Tamanho: $tamanho\n' : ''}'
        'Quantidade: $qtd\n'
        'Total: R\$ ${(p.preco * qtd).toStringAsFixed(2)}\n'
        '${obs != null ? 'Obs: $obs\n' : ''}\n'
        'Verifique o app para confirmar! 🥋';
    final uri = Uri.parse('https://wa.me/$professorTel?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Pedido enviado! Acompanhe em "Meus Pedidos".'),
        backgroundColor: verdeEscuro,
      ));
      // Navega para Meus Pedidos
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const MeusPedidosScreen()));
    }
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
  final _obsCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  @override
  void dispose() { _obsCtrl.dispose(); _telCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Solicitar: ${p.nome}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        Text('R\$ ${p.preco.toStringAsFixed(2)} / unidade', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 16),

        // Telefone de contato
        TextField(controller: _telCtrl,
          decoration: const InputDecoration(labelText: 'Seu telefone (para contato)', prefixIcon: Icon(Icons.phone_outlined), isDense: true),
          keyboardType: TextInputType.phone),
        const SizedBox(height: 12),

        // Cor
        const Text('Cor (opcional):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(onChanged: (v) => setState(() => _cor = v.isEmpty ? null : v),
          decoration: const InputDecoration(hintText: 'Ex: Branco, Azul, Preto...', isDense: true)),
        const SizedBox(height: 12),

        // Tamanho
        const Text('Tamanho (opcional):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(onChanged: (v) => setState(() => _tamanho = v.isEmpty ? null : v),
          decoration: const InputDecoration(hintText: 'Ex: A2, M, G...', isDense: true)),
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

        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, {
            'cor': _cor, 'tamanho': _tamanho, 'quantidade': _qtd,
            'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
            'telefone': _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
          }),
          icon: const Icon(Icons.message),
          label: Text('Enviar Pedido — R\$ ${(p.preco * _qtd).toStringAsFixed(2)}'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
        ),
      ])),
    );
  }
}

class _ProdutoCard extends StatelessWidget {
  final Produto produto;
  final String catLabel;
  final Color catColor;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSolicitar;
  const _ProdutoCard({required this.produto, required this.catLabel, required this.catColor, required this.isAdmin, this.onEdit, this.onDelete, this.onSolicitar});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        opacity: produto.ativo ? 1.0 : 0.5,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _ProdutoImagem(fotoUrl: produto.fotoUrl, youtubeThumb: produto.youtubeThumbnail)),
          Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Chip(label: Text(catLabel, style: const TextStyle(fontSize: 10)), backgroundColor: catColor.withOpacity(0.15),
              padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            const SizedBox(height: 4),
            Text('R\$ ${produto.preco.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: verdeEscuro)),
            Text(produto.prazoLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            if (isAdmin) Row(children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18, color: verdeEscuro), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
            if (!isAdmin) ...[
              const SizedBox(height: 6),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: onSolicitar,
                icon: const Icon(Icons.message, size: 14),
                label: const Text('Solicitar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.green.shade600,
                ),
              )),
            ],
          ])),
        ]),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  const _PlaceholderImg();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey.shade100,
    child: const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
  );
}

class _ProdutoImagem extends StatelessWidget {
  final String? fotoUrl;
  final String? youtubeThumb;
  const _ProdutoImagem({this.fotoUrl, this.youtubeThumb});

  @override
  Widget build(BuildContext context) {
    // Prioridade: foto local/URL > thumbnail YouTube > placeholder
    final path = fotoUrl?.isNotEmpty == true ? fotoUrl : null;

    if (path != null) {
      return imageWidgetFromPath(path, fit: BoxFit.cover, errorWidget: _fallbackYoutube(youtubeThumb));
    }

    return _fallbackYoutube(youtubeThumb);
  }

  Widget _fallbackYoutube(String? thumb) {
    if (thumb != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.network(thumb, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _PlaceholderImg()),
        const Center(child: Icon(Icons.play_circle_filled, color: Colors.white, size: 40)),
      ]);
    }
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

  // Grade de variantes: lista de {cor, tamanho, estoque}
  final List<Map<String, dynamic>> _variantes = [];

  // Cores e tamanhos comuns para sugestão
  static const _coresSugeridas = ['Branco', 'Preto', 'Azul', 'Verde', 'Cinza', 'Vermelho', 'Amarelo'];
  static const _tamanhosSugeridos = ['PP', 'P', 'M', 'G', 'GG', 'A0', 'A1', 'A2', 'A3', 'A4'];

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
      _prazoDataCtrl.text = p.prazoData ?? '';
      _categoria = p.categoria;
      _prazoEntrega = p.prazoEntrega;
      _ativo = p.ativo;
      _fotoUrl = p.fotoUrl;
    }
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

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _fotoUrl = img.path);
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final p = Produto(
      id: widget.produto?.id ?? _uuid.v4(),
      nome: _nomeCtrl.text.trim(),
      categoria: _categoria,
      descricao: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      preco: double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0,
      fotoUrl: _fotoUrl,
      youtubeUrl: _youtubeCtrl.text.trim().isEmpty ? null : _youtubeCtrl.text.trim(),
      prazoEntrega: _prazoEntrega,
      prazoDias: int.tryParse(_prazoDiasCtrl.text) ?? 0,
      prazoData: _prazoDataCtrl.text.trim().isEmpty ? null : _prazoDataCtrl.text.trim(),
      ativo: _ativo,
      createdAt: widget.produto?.createdAt,
    );
    if (widget.produto != null) { await _repo.atualizar(p); } else { await _repo.criar(p); }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
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
            child: _fotoUrl != null
                ? Stack(fit: StackFit.expand, children: [
                    imageWidgetFromPath(_fotoUrl!, fit: BoxFit.cover),
                    Positioned(bottom: 6, right: 6,
                      child: Container(padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14))),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey),
                    Text('Toque para adicionar foto', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
          TextField(controller: _prazoDataCtrl,
            decoration: const InputDecoration(labelText: 'Data de entrega (DD/MM/AAAA)', isDense: true),
            keyboardType: TextInputType.datetime),
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




