class Mensalidade {
  final String id;
  final String alunoId;
  final String? alunoNome;
  final int mes;
  final int ano;
  final double valor;
  final String status; // pendente | pago | atrasado
  final String? dataPagamento;
  final String? observacao;
  final String? createdAt;

  const Mensalidade({
    required this.id,
    required this.alunoId,
    this.alunoNome,
    required this.mes,
    required this.ano,
    required this.valor,
    this.status = 'pendente',
    this.dataPagamento,
    this.observacao,
    this.createdAt,
  });

  factory Mensalidade.fromMap(Map<String, dynamic> m) => Mensalidade(
        id: m['id'],
        alunoId: m['aluno_id'],
        alunoNome: m['aluno_nome'],
        mes: m['mes'],
        ano: m['ano'],
        valor: (m['valor'] as num).toDouble(),
        status: m['status'] ?? 'pendente',
        dataPagamento: m['data_pagamento'],
        observacao: m['observacao'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'aluno_nome': alunoNome,
        'mes': mes,
        'ano': ano,
        'valor': valor,
        'status': status,
        'data_pagamento': dataPagamento,
        'observacao': observacao,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
      };

  Mensalidade copyWith({String? status, String? dataPagamento, String? observacao}) =>
      Mensalidade(
        id: id,
        alunoId: alunoId,
        alunoNome: alunoNome,
        mes: mes,
        ano: ano,
        valor: valor,
        status: status ?? this.status,
        dataPagamento: dataPagamento ?? this.dataPagamento,
        observacao: observacao ?? this.observacao,
        createdAt: createdAt,
      );
}
