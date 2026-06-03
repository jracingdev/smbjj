class Produto {
  final String id;
  final String nome;
  final String categoria; // kimono | faixa | camisa | short | outro
  final String? descricao;
  final double preco;
  final String? fotoUrl;
  final String? youtubeUrl;
  final String prazoEntrega; // imediato | dias | data
  final int prazoDias;
  final String? prazoData;
  final bool ativo;
  final String? createdAt;

  const Produto({
    required this.id,
    required this.nome,
    this.categoria = 'kimono',
    this.descricao,
    required this.preco,
    this.fotoUrl,
    this.youtubeUrl,
    this.prazoEntrega = 'imediato',
    this.prazoDias = 0,
    this.prazoData,
    this.ativo = true,
    this.createdAt,
  });

  String get prazoLabel {
    switch (prazoEntrega) {
      case 'dias': return 'Entrega em $prazoDias dia(s)';
      case 'data': return 'Entrega: ${prazoData ?? '—'}';
      default: return 'Retirada imediata';
    }
  }

  String? get youtubeThumbnail {
    if (youtubeUrl == null || youtubeUrl!.isEmpty) return null;
    final match = RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})').firstMatch(youtubeUrl!);
    return match != null ? 'https://img.youtube.com/vi/${match.group(1)}/mqdefault.jpg' : null;
  }

  int get estoqueTotal => 0; // calculado via variantes

  factory Produto.fromMap(Map<String, dynamic> m) => Produto(
        id: m['id'],
        nome: m['nome'],
        categoria: m['categoria'] ?? 'kimono',
        descricao: m['descricao'],
        preco: (m['preco'] as num).toDouble(),
        fotoUrl: m['foto_url'],
        youtubeUrl: m['youtube_url'],
        prazoEntrega: m['prazo_entrega'] ?? 'imediato',
        prazoDias: m['prazo_dias'] ?? 0,
        prazoData: m['prazo_data'],
        ativo: (m['ativo'] is bool ? m['ativo'] : (m['ativo'] ?? 1) == 1),
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'categoria': categoria,
        'descricao': descricao,
        'preco': preco,
        'foto_url': fotoUrl,
        'youtube_url': youtubeUrl,
        'prazo_entrega': prazoEntrega,
        'prazo_dias': prazoDias,
        'prazo_data': prazoData,
        'ativo': ativo,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
      };
}

