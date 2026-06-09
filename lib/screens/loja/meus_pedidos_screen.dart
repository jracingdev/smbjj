import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/pedido.dart';
import '../../core/supabase_errors.dart';
import '../../repositories/pedido_repository.dart';
import '../../widgets/pedidos_erro_view.dart';
import '../../utils/date_utils.dart';

class MeusPedidosScreen extends StatefulWidget {
  const MeusPedidosScreen({super.key});
  @override
  State<MeusPedidosScreen> createState() => _MeusPedidosScreenState();
}

class _MeusPedidosScreenState extends State<MeusPedidosScreen> {
  final _repo = PedidoRepository();
  List<Pedido> _pedidos = [];
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
      final auth = context.read<AuthProvider>();
      final email = (auth.usuario?.email ?? auth.alunoVinculado?.email ?? '').trim();
      if (email.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _erro = 'Não foi possível identificar seu e-mail. Saia e entre novamente.';
            _pedidos = [];
          });
        }
        return;
      }
      final data = await _repo.meusPedidos(email);
      if (mounted) setState(() { _pedidos = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _pedidos = [];
          _loading = false;
          _erro = mensagemErroSupabase(e, recurso: 'seus pedidos');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pedidos'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : _erro != null
              ? PedidosErroView(mensagem: _erro!, onRetry: _load)
              : _pedidos.isEmpty
              ? const PedidosListaVazia(
                  titulo: 'Nenhum pedido ainda',
                  subtitulo: 'Solicite um produto na Loja e acompanhe o status aqui.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom + 20),
                    itemCount: _pedidos.length,
                    itemBuilder: (_, i) => _MeuPedidoCard(pedido: _pedidos[i]),
                  ),
                ),
    );
  }
}

class _MeuPedidoCard extends StatefulWidget {
  final Pedido pedido;
  const _MeuPedidoCard({required this.pedido});
  @override
  State<_MeuPedidoCard> createState() => _MeuPedidoCardState();
}

class _MeuPedidoCardState extends State<_MeuPedidoCard> {
  bool _expanded = false;

  static const _statusColor = {
    'pendente': Colors.orange, 'confirmado': Colors.blue,
    'preparando': Colors.deepOrange, 'enviado': Colors.teal,
    'entregue': Colors.green, 'cancelado': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final cor = _statusColor[p.status] ?? Colors.grey;
    final stepIndex = Pedido.statusOrder.indexOf(p.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 4, height: 56, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.produtoNome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                if (p.varianteLabel.isNotEmpty)
                  Text(p.varianteLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text('${p.quantidade}x · R\$ ${p.valorTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(p.statusTexto, style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w700))),
                const SizedBox(height: 4),
                Text(p.pago ? '💚 Pago' : '🔴 Aguardando pgto.',
                    style: TextStyle(fontSize: 10, color: p.pago ? Colors.green : Colors.orange)),
              ]),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
            ]),
          ),
        ),

        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Divider(),

            // Timeline de status
            if (p.status != 'cancelado') ...[
              const Text('Acompanhamento do Pedido:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 10),
              Row(children: Pedido.statusOrder.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final done = stepIndex >= idx;
                final isCurrent = stepIndex == idx;
                return Expanded(child: Column(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: done ? verdeEscuro : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: isCurrent ? Border.all(color: verdeEscuro, width: 2) : null,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.radio_button_unchecked,
                      size: 16,
                      color: done ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_shortLabel(s), style: TextStyle(fontSize: 9, color: done ? verdeEscuro : Colors.grey,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
                ]));
              }).toList()),
              const SizedBox(height: 12),
            ],

            if (p.status == 'cancelado')
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Text('❌ Seu pedido foi cancelado. Entre em contato com o professor.',
                    style: TextStyle(color: Colors.red, fontSize: 13))),

            // Rastreamento
            if (p.codigoRastreamento != null && p.status == 'enviado' || p.status == 'entregue') ...[
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📦 Seu pedido foi enviado!', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.teal, fontSize: 14)),
                  if (p.transportadora != null) Text('Transportadora: ${p.transportadora}', style: const TextStyle(fontSize: 12)),
                  if (p.codigoRastreamento != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: p.codigoRastreamento!));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
                      },
                      child: Row(children: [
                        const Icon(Icons.copy, size: 14, color: Colors.teal),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Código: ${p.codigoRastreamento}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.teal))),
                      ]),
                    ),
                    const Text('(toque para copiar)', style: TextStyle(fontSize: 10, color: Colors.teal)),
                  ],
                  if (p.dataEntregaEstimada != null) ...[
                    const SizedBox(height: 4),
                    Text('📅 Previsão de entrega: ${formatDataBr(p.dataEntregaEstimada)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                  if (p.linkRastreamento != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(p.linkRastreamento!);
                        if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Rastrear meu pedido'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    )),
                  ],
                ]),
              ),
              const SizedBox(height: 10),
            ],

            // PIX à vista
            if (!p.pago && p.formaPagamento == 'pix') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('PIX — R\$ ${p.valorTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: verdeEscuro)),
                  const SizedBox(height: 4),
                  Text('$pixNome · $pixKey', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: pixKey));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave PIX copiada!')));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar chave PIX'),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],

            // Link de pagamento Mercado Pago
            if (!p.pago && p.linkPagamento != null) ...[
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(p.linkPagamento!);
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.payment),
                label: Text('Pagar agora — R\$ ${p.valorTotal.toStringAsFixed(2)}'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              )),
              const SizedBox(height: 6),
            ],

            // Botão WhatsApp professor
            OutlinedButton.icon(
              onPressed: () async {
                const professorTel = '5521975396996';
                final msg = '📦 Olá professor! Gostaria de saber sobre meu pedido:\n\n'
                    '*${p.produtoNome}*${p.varianteLabel.isNotEmpty ? ' (${p.varianteLabel})' : ''}\n'
                    'Status atual: ${p.statusTexto}\n\n'
                    'Pode me dar uma atualização? 🙏';
                final uri = Uri.parse('https://wa.me/$professorTel?text=${Uri.encodeComponent(msg)}');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Falar com o professor'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
            ),

            if (p.observacoesAdmin != null) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.observacoesAdmin!, style: const TextStyle(fontSize: 12, color: Colors.blue))),
                ])),
            ],
          ]),
        ),
      ]),
    );
  }

  String _shortLabel(String s) {
    switch (s) {
      case 'pendente': return 'Pendente';
      case 'confirmado': return 'Confirmado';
      case 'preparando': return 'Preparando';
      case 'enviado': return 'Enviado';
      case 'entregue': return 'Entregue';
      default: return s;
    }
  }
}
