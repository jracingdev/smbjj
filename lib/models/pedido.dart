class Pedido {
  final String id;
  // Comprador
  final String? alunoId;
  final String alunoNome;
  final String? alunoEmail;
  final String? alunoTelefone;
  // Produto
  final String? produtoId;
  final String produtoNome;
  final String? varianteCor;
  final String? varianteTamanho;
  final int quantidade;
  final double valorUnitario;
  final double valorTotal;
  // Status
  final String status; // pendente|confirmado|preparando|enviado|entregue|cancelado
  // Pagamento
  final String formaPagamento; // whatsapp|mercadopago|pix|dinheiro
  final String? linkPagamento;
  final bool pago;
  final String? dataPagamento;
  // Entrega
  final String? codigoRastreamento;
  final String? transportadora;
  final String? linkRastreamento;
  final String? dataEnvio;
  final String? dataEntregaEstimada;
  // Extras
  final String? observacoes;
  final String? observacoesAdmin;
  final String? createdAt;

  const Pedido({
    required this.id,
    this.alunoId,
    required this.alunoNome,
    this.alunoEmail,
    this.alunoTelefone,
    this.produtoId,
    required this.produtoNome,
    this.varianteCor,
    this.varianteTamanho,
    this.quantidade = 1,
    required this.valorUnitario,
    required this.valorTotal,
    this.status = 'pendente',
    this.formaPagamento = 'whatsapp',
    this.linkPagamento,
    this.pago = false,
    this.dataPagamento,
    this.codigoRastreamento,
    this.transportadora,
    this.linkRastreamento,
    this.dataEnvio,
    this.dataEntregaEstimada,
    this.observacoes,
    this.observacoesAdmin,
    this.createdAt,
  });

  static const statusLabel = {
    'pendente':    '🟡 Pendente',
    'confirmado':  '🔵 Confirmado',
    'preparando':  '🟠 Preparando',
    'enviado':     '🚚 Enviado',
    'entregue':    '✅ Entregue',
    'cancelado':   '❌ Cancelado',
  };

  static const statusOrder = ['pendente', 'confirmado', 'preparando', 'enviado', 'entregue'];

  String get statusTexto => statusLabel[status] ?? status;

  String get varianteLabel {
    final parts = [if (varianteCor != null) varianteCor!, if (varianteTamanho != null) varianteTamanho!];
    return parts.isEmpty ? '' : parts.join(' / ');
  }

  /// Pedido feito por visitante na loja web (sem login de aluno).
  bool get compradorVisitante => alunoId == null || alunoId!.isEmpty;

  factory Pedido.fromMap(Map<String, dynamic> m) => Pedido(
        id: m['id'],
        alunoId: m['aluno_id'],
        alunoNome: m['aluno_nome'] ?? '',
        alunoEmail: m['aluno_email'],
        alunoTelefone: m['aluno_telefone'],
        produtoId: m['produto_id'],
        produtoNome: m['produto_nome'] ?? '',
        varianteCor: m['variante_cor'],
        varianteTamanho: m['variante_tamanho'],
        quantidade: m['quantidade'] ?? 1,
        valorUnitario: (m['valor_unitario'] as num?)?.toDouble() ?? 0,
        valorTotal: (m['valor_total'] as num?)?.toDouble() ?? 0,
        status: m['status'] ?? 'pendente',
        formaPagamento: m['forma_pagamento'] ?? 'whatsapp',
        linkPagamento: m['link_pagamento'],
        pago: m['pago'] == true,
        dataPagamento: m['data_pagamento'],
        codigoRastreamento: m['codigo_rastreamento'],
        transportadora: m['transportadora'],
        linkRastreamento: m['link_rastreamento'],
        dataEnvio: m['data_envio'],
        dataEntregaEstimada: m['data_entrega_estimada'],
        observacoes: m['observacoes'],
        observacoesAdmin: m['observacoes_admin'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'aluno_nome': alunoNome,
        'aluno_email': alunoEmail,
        'aluno_telefone': alunoTelefone,
        'produto_id': produtoId,
        'produto_nome': produtoNome,
        'variante_cor': varianteCor,
        'variante_tamanho': varianteTamanho,
        'quantidade': quantidade,
        'valor_unitario': valorUnitario,
        'valor_total': valorTotal,
        'status': status,
        'forma_pagamento': formaPagamento,
        'link_pagamento': linkPagamento,
        'pago': pago,
        'data_pagamento': dataPagamento,
        'codigo_rastreamento': codigoRastreamento,
        'transportadora': transportadora,
        'link_rastreamento': linkRastreamento,
        'data_envio': dataEnvio,
        'data_entrega_estimada': dataEntregaEstimada,
        'observacoes': observacoes,
        'observacoes_admin': observacoesAdmin,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
}
