class ProdutoVariante {
  final String id;
  final String produtoId;
  final String? cor;
  final String? tamanho;
  final int estoque;

  const ProdutoVariante({
    required this.id,
    required this.produtoId,
    this.cor,
    this.tamanho,
    this.estoque = 0,
  });

  factory ProdutoVariante.fromMap(Map<String, dynamic> m) => ProdutoVariante(
        id: m['id'],
        produtoId: m['produto_id'],
        cor: m['cor'],
        tamanho: m['tamanho'],
        estoque: m['estoque'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'produto_id': produtoId,
        'cor': cor,
        'tamanho': tamanho,
        'estoque': estoque,
      };

  ProdutoVariante copyWith({String? cor, String? tamanho, int? estoque}) =>
      ProdutoVariante(
        id: id,
        produtoId: produtoId,
        cor: cor ?? this.cor,
        tamanho: tamanho ?? this.tamanho,
        estoque: estoque ?? this.estoque,
      );

  String get label {
    final parts = [if (cor != null) cor!, if (tamanho != null) tamanho!];
    return parts.join(' / ');
  }
}
