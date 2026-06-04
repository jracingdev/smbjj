class RegraFinanceira {
  final String id;
  final String titulo;
  /// desconto_percent | dia_whatsapp | texto | valor_mensalidade
  final String tipo;
  final double valor;
  final String? descricao;
  final bool ativa;

  const RegraFinanceira({
    required this.id,
    required this.titulo,
    required this.tipo,
    this.valor = 0,
    this.descricao,
    this.ativa = true,
  });

  factory RegraFinanceira.fromMap(Map<String, dynamic> m) => RegraFinanceira(
        id: m['id']?.toString() ?? '',
        titulo: m['titulo'] as String? ?? '',
        tipo: m['tipo'] as String? ?? 'texto',
        valor: (m['valor'] as num?)?.toDouble() ?? 0,
        descricao: m['descricao'] as String?,
        ativa: m['ativa'] != false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'tipo': tipo,
        'valor': valor,
        'descricao': descricao,
        'ativa': ativa,
      };

  String get valorExibicao {
    switch (tipo) {
      case 'desconto_percent':
        return '${valor.toStringAsFixed(0)}% off';
      case 'dia_whatsapp':
        return 'Dia ${valor.toInt()}';
      case 'valor_mensalidade':
        return 'R\$ ${valor.toStringAsFixed(2)}';
      default:
        return descricao ?? '—';
    }
  }

  RegraFinanceira copyWith({
    String? titulo,
    String? tipo,
    double? valor,
    String? descricao,
    bool? ativa,
  }) =>
      RegraFinanceira(
        id: id,
        titulo: titulo ?? this.titulo,
        tipo: tipo ?? this.tipo,
        valor: valor ?? this.valor,
        descricao: descricao ?? this.descricao,
        ativa: ativa ?? this.ativa,
      );
}
