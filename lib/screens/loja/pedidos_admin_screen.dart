import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/mp_service.dart';
import '../../core/theme.dart';
import '../../models/pedido.dart';
import '../../core/supabase_errors.dart';
import '../../repositories/pedido_repository.dart';
import '../../widgets/pedidos_erro_view.dart';
import '../../utils/date_utils.dart';

class PedidosAdminScreen extends StatefulWidget {
  const PedidosAdminScreen({super.key});
  @override
  State<PedidosAdminScreen> createState() => _PedidosAdminScreenState();
}

class _PedidosAdminScreenState extends State<PedidosAdminScreen> {
  final _repo = PedidoRepository();
  List<Pedido> _todos = [];
  String _filtroStatus = 'todos';
  bool _loading = true;
  String? _erro;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final data = await _repo.listar();
      if (mounted) setState(() { _todos = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _todos = [];
          _loading = false;
          _erro = mensagemErroSupabase(e, recurso: 'os pedidos');
        });
      }
    }
  }

  List<Pedido> get _filtrados =>
      _filtroStatus == 'todos' ? _todos : _todos.where((p) => p.status == _filtroStatus).toList();

  @override
  Widget build(BuildContext context) {
    final contadores = <String, int>{};
    for (final p in _todos) contadores[p.status] = (contadores[p.status] ?? 0) + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos da Loja'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: Column(children: [
        // Filtros por status
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _FiltroBtn(label: 'Todos (${_todos.length})', selected: _filtroStatus == 'todos', onTap: () => setState(() => _filtroStatus = 'todos')),
            _FiltroBtn(label: '🟡 Pendentes (${contadores['pendente'] ?? 0})', selected: _filtroStatus == 'pendente', onTap: () => setState(() => _filtroStatus = 'pendente')),
            _FiltroBtn(label: '🔵 Confirmados (${contadores['confirmado'] ?? 0})', selected: _filtroStatus == 'confirmado', onTap: () => setState(() => _filtroStatus = 'confirmado')),
            _FiltroBtn(label: '🟠 Preparando (${contadores['preparando'] ?? 0})', selected: _filtroStatus == 'preparando', onTap: () => setState(() => _filtroStatus = 'preparando')),
            _FiltroBtn(label: '🚚 Enviados (${contadores['enviado'] ?? 0})', selected: _filtroStatus == 'enviado', onTap: () => setState(() => _filtroStatus = 'enviado')),
            _FiltroBtn(label: '✅ Entregues (${contadores['entregue'] ?? 0})', selected: _filtroStatus == 'entregue', onTap: () => setState(() => _filtroStatus = 'entregue')),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
              : _erro != null
                  ? PedidosErroView(mensagem: _erro!, onRetry: _load)
                  : _filtrados.isEmpty
                  ? const PedidosListaVazia(
                      titulo: 'Nenhum pedido na loja',
                      subtitulo: 'Quando alunos solicitarem produtos, eles aparecerão aqui.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.of(context).padding.bottom + 20),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) => _PedidoAdminCard(
                          pedido: _filtrados[i],
                          onUpdate: _load,
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _FiltroBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FiltroBtn({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(label: Text(label, style: const TextStyle(fontSize: 12)), selected: selected,
      onSelected: (_) => onTap(), selectedColor: verdeEscuro.withValues(alpha: 0.15),
      checkmarkColor: verdeEscuro),
  );
}

class _PedidoAdminCard extends StatefulWidget {
  final Pedido pedido;
  final VoidCallback onUpdate;
  const _PedidoAdminCard({required this.pedido, required this.onUpdate});
  @override
  State<_PedidoAdminCard> createState() => _PedidoAdminCardState();
}

class _PedidoAdminCardState extends State<_PedidoAdminCard> {
  final _repo = PedidoRepository();
  late final TextEditingController _codRastreioCtrl;
  bool _expanded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _codRastreioCtrl = TextEditingController(text: widget.pedido.codigoRastreamento ?? '');
  }

  @override
  void didUpdateWidget(covariant _PedidoAdminCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pedido.codigoRastreamento != widget.pedido.codigoRastreamento) {
      _codRastreioCtrl.text = widget.pedido.codigoRastreamento ?? '';
    }
  }

  @override
  void dispose() {
    _codRastreioCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarCodigoRastreio() async {
    final cod = _codRastreioCtrl.text.trim();
    setState(() => _loading = true);
    await _repo.atualizarRastreamento(
      widget.pedido.id,
      codigo: cod.isEmpty ? null : cod,
      transportadora: widget.pedido.transportadora,
      link: widget.pedido.linkRastreamento,
      dataEntrega: widget.pedido.dataEntregaEstimada,
    );
    setState(() => _loading = false);
    widget.onUpdate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de rastreamento salvo.'), backgroundColor: verdeEscuro),
      );
    }
  }

  static const _statusColor = {
    'pendente': Colors.orange, 'confirmado': Colors.blue,
    'preparando': Colors.deepOrange, 'enviado': Colors.teal,
    'entregue': Colors.green, 'cancelado': Colors.red,
  };

  Future<void> _atualizarStatus(String novo) async {
    setState(() => _loading = true);
    await _repo.atualizarStatus(widget.pedido.id, novo);
    // Notifica aluno via WhatsApp
    final tel = widget.pedido.alunoTelefone;
    if (tel != null && tel.isNotEmpty) {
      final msg = '📦 Olá ${widget.pedido.alunoNome}!\n\n'
          'Atualização do seu pedido:\n'
          '*${widget.pedido.produtoNome}*\n\n'
          'Status: ${Pedido.statusLabel[novo]}\n'
          '${_msgExtra(novo, widget.pedido)}\n\n'
          'SM BJJ 🥋';
      final num = tel.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('https://wa.me/55$num?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    widget.onUpdate();
  }

  String _msgExtra(String status, Pedido p) {
    switch (status) {
      case 'enviado': return p.codigoRastreamento != null
          ? 'Código de rastreamento: *${p.codigoRastreamento}*' : '';
      case 'entregue': return 'Seu pedido foi entregue! Obrigado pela confiança.';
      default: return '';
    }
  }

  Future<void> _gerarLinkMP() async {
    setState(() => _loading = true);
    final pref = await MercadoPagoService.instance.criarCobranca(
      titulo: 'Pedido ${widget.pedido.produtoNome} - SM BJJ',
      valor: widget.pedido.valorTotal,
      emailPagador: widget.pedido.alunoEmail,
      descricao: '${widget.pedido.produtoNome}${widget.pedido.varianteLabel.isNotEmpty ? ' (${widget.pedido.varianteLabel})' : ''} - Qtd: ${widget.pedido.quantidade}',
    );
    setState(() => _loading = false);
    if (pref == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configure o Mercado Pago primeiro.'), backgroundColor: Colors.red));
      return;
    }
    await _repo.atualizarLinkPagamento(widget.pedido.id, pref.link);
    // Envia para aluno
    final tel = widget.pedido.alunoTelefone;
    if (tel != null) {
      final msg = '💳 Olá ${widget.pedido.alunoNome}!\n\n'
          'Segue o link de pagamento do seu pedido:\n'
          '*${widget.pedido.produtoNome}*\n'
          'Valor: R\$ ${widget.pedido.valorTotal.toStringAsFixed(2)}\n\n'
          '🔗 ${pref.link}\n\n'
          'PIX, cartão e boleto disponíveis! 🥋';
      final num = tel.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('https://wa.me/55$num?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    widget.onUpdate();
  }

  Future<void> _editarRastreamento() async {
    final codCtrl = TextEditingController(text: widget.pedido.codigoRastreamento ?? '');
    final transpCtrl = TextEditingController(text: widget.pedido.transportadora ?? '');
    final linkCtrl = TextEditingController(text: widget.pedido.linkRastreamento ?? '');
    final dataCtrl = TextEditingController(
      text: widget.pedido.dataEntregaEstimada != null
          ? formatDataBr(widget.pedido.dataEntregaEstimada)
          : '',
    );

    await showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Informações de Rastreamento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(controller: codCtrl, decoration: const InputDecoration(labelText: 'Código de Rastreamento', prefixIcon: Icon(Icons.local_shipping_outlined), isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: transpCtrl, decoration: const InputDecoration(labelText: 'Transportadora', hintText: 'Ex: Correios, Jadlog...', isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Link de Rastreamento', hintText: 'https://...', isDense: true), keyboardType: TextInputType.url),
            const SizedBox(height: 10),
            TextField(
              controller: dataCtrl,
              decoration: InputDecoration(labelText: 'Previsão de Entrega', hintText: hintDataCompleta, isDense: true),
              inputFormatters: [DataNascimentoInputFormatter()],
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _repo.atualizarRastreamento(widget.pedido.id,
                  codigo: codCtrl.text.trim().isEmpty ? null : codCtrl.text.trim(),
                  transportadora: transpCtrl.text.trim().isEmpty ? null : transpCtrl.text.trim(),
                  link: linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
                  dataEntrega: () {
                    final t = dataCtrl.text.trim();
                    if (t.isEmpty) return null;
                    return dataCompletaParaIso(t) ?? t;
                  }(),
                );
                widget.onUpdate();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar Rastreamento'),
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final cor = _statusColor[p.status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        // Header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 4, height: 48, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.produtoNome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (p.compradorVisitante ? Colors.deepPurple : verdeEscuro).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.compradorVisitante ? '🌐 Visitante' : '🥋 Aluno',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: p.compradorVisitante ? Colors.deepPurple.shade700 : verdeEscuro,
                        ),
                      ),
                    ),
                  ],
                ),
                Text('${p.alunoNome} · ${p.quantidade}x R\$ ${p.valorTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (p.varianteLabel.isNotEmpty)
                  Text(p.varianteLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(p.statusTexto, style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w700))),
                const SizedBox(height: 4),
                Text(p.pago ? '💚 Pago' : '🔴 Não pago',
                    style: TextStyle(fontSize: 11, color: p.pago ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
              ]),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
            ]),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codRastreioCtrl,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: 'Código de rastreamento',
                    prefixIcon: const Icon(Icons.local_shipping_outlined, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _salvarCodigoRastreio(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Salvar código',
                onPressed: _loading ? null : _salvarCodigoRastreio,
                icon: const Icon(Icons.save_outlined, color: verdeEscuro),
              ),
              IconButton(
                tooltip: 'Mais dados de envio',
                onPressed: _editarRastreamento,
                icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),

        // Expandido
        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Divider(),

            // Dados do aluno
            _infoRow(Icons.person_outline, p.compradorVisitante ? 'Visitante (loja web)' : 'Aluno logado', p.alunoNome),
            if (p.alunoTelefone != null) _infoRow(Icons.phone_outlined, 'Telefone', p.alunoTelefone!),
            if (p.alunoEmail != null) _infoRow(Icons.email_outlined, 'Email', p.alunoEmail!),
            if (p.observacoes != null) _infoRow(Icons.comment_outlined, 'Obs. aluno', p.observacoes!),
            if (p.createdAt != null) _infoRow(Icons.access_time, 'Data pedido', formatDataBr(p.createdAt!.substring(0, 10))),

            // Rastreamento
            if (p.codigoRastreamento != null) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📦 Rastreamento', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.teal)),
                  if (p.transportadora != null) Text('Transportadora: ${p.transportadora}', style: const TextStyle(fontSize: 12)),
                  GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: p.codigoRastreamento!)),
                    child: Text('Código: ${p.codigoRastreamento} (toque p/ copiar)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  if (p.dataEntregaEstimada != null)
                    Text('Previsão: ${formatDataBr(p.dataEntregaEstimada)}', style: const TextStyle(fontSize: 12)),
                  if (p.linkRastreamento != null) GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(p.linkRastreamento!);
                      if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text('🔗 Rastrear online', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ],

            // Obs admin
            if (p.observacoesAdmin != null) _infoRow(Icons.admin_panel_settings_outlined, 'Obs. interna', p.observacoesAdmin!),

            const SizedBox(height: 12),

            // Ações de status
            const Text('Atualizar Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ...Pedido.statusOrder.where((s) => s != p.status).map((s) => ActionChip(
                label: Text(Pedido.statusLabel[s] ?? s, style: const TextStyle(fontSize: 11)),
                onPressed: _loading ? null : () => _atualizarStatus(s),
              )),
              ActionChip(
                label: const Text('❌ Cancelar', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.red.shade50,
                labelStyle: const TextStyle(color: Colors.red),
                onPressed: _loading ? null : () => _atualizarStatus('cancelado'),
              ),
            ]),

            const SizedBox(height: 10),

            // Ações de pagamento e rastreamento
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (!p.pago) ElevatedButton.icon(
                onPressed: _loading ? null : () async {
                  await _repo.marcarPago(widget.pedido.id);
                  widget.onUpdate();
                },
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Marcar Pago', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: Colors.green),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _gerarLinkMP,
                icon: const Icon(Icons.payment, size: 14),
                label: const Text('Link MP', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              ElevatedButton.icon(
                onPressed: _editarRastreamento,
                icon: const Icon(Icons.local_shipping_outlined, size: 14),
                label: const Text('Rastreamento', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.teal,
                ),
              ),
              if (p.alunoTelefone != null) OutlinedButton.icon(
                onPressed: () async {
                  final msg = '📦 Olá ${p.alunoNome}! Temos uma atualização do seu pedido *${p.produtoNome}*. Entre em contato conosco. SM BJJ 🥋';
                  final num = p.alunoTelefone!.replaceAll(RegExp(r'\D'), '');
                  final uri = Uri.parse('https://wa.me/55$num?text=${Uri.encodeComponent(msg)}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.message, size: 14),
                label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: Colors.green),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(context: context,
                    builder: (_) => AlertDialog(content: Text('Remover pedido de ${p.alunoNome}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
                      ]));
                  if (ok == true) { await _repo.deletar(p.id); widget.onUpdate(); }
                },
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('Remover', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: Colors.red),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(icon, size: 15, color: Colors.grey.shade500),
      const SizedBox(width: 6),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}
