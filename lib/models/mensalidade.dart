class Mensalidade {
  final String id;
  final String alunoId;
  final String? alunoNome;
  final int mes;
  final int ano;
  final double valor;
  final double? valorBase;
  final String status; // pendente | pago | atrasado
  final String? dataPagamento;
  final String? observacao;
  final bool cancelada;
  final bool proRata;
  final String? createdAt;
  final String? mpPreferenciaId;

  const Mensalidade({
    required this.id,
    required this.alunoId,
    this.alunoNome,
    required this.mes,
    required this.ano,
    required this.valor,
    this.valorBase,
    this.status = 'pendente',
    this.dataPagamento,
    this.observacao,
    this.cancelada = false,
    this.proRata = false,
    this.createdAt,
    this.mpPreferenciaId,
  });

  factory Mensalidade.fromMap(Map<String, dynamic> m) => Mensalidade(
        id: m['id'],
        alunoId: m['aluno_id'],
        alunoNome: m['aluno_nome'],
        mes: m['mes'],
        ano: m['ano'],
        valor: (m['valor'] as num).toDouble(),
        valorBase: (m['valor_base'] as num?)?.toDouble(),
        status: m['status'] ?? 'pendente',
        dataPagamento: m['data_pagamento'],
        observacao: m['observacao'],
        cancelada: m['cancelada'] == true,
        proRata: m['pro_rata'] == true,
        createdAt: m['created_at'],
        mpPreferenciaId: m['mp_preferencia_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'aluno_nome': alunoNome,
        'mes': mes,
        'ano': ano,
        'valor': valor,
        if (valorBase != null) 'valor_base': valorBase,
        'status': status,
        'data_pagamento': dataPagamento,
        'observacao': observacao,
        'cancelada': cancelada,
        'pro_rata': proRata,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'mp_preferencia_id': mpPreferenciaId,
      };

  Mensalidade copyWith({
    String? status,
    String? dataPagamento,
    String? observacao,
    double? valor,
    bool? cancelada,
    bool? proRata,
    double? valorBase,
    String? mpPreferenciaId,
    bool limparMpPreferencia = false,
    bool limparDataPagamento = false,
  }) =>
      Mensalidade(
        id: id,
        alunoId: alunoId,
        alunoNome: alunoNome,
        mes: mes,
        ano: ano,
        valor: valor ?? this.valor,
        valorBase: valorBase ?? this.valorBase,
        status: status ?? this.status,
        dataPagamento: limparDataPagamento ? null : (dataPagamento ?? this.dataPagamento),
        observacao: observacao ?? this.observacao,
        cancelada: cancelada ?? this.cancelada,
        proRata: proRata ?? this.proRata,
        createdAt: createdAt,
        mpPreferenciaId: limparMpPreferencia ? null : (mpPreferenciaId ?? this.mpPreferenciaId),
      );
}
