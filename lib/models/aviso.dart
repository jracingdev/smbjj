class Aviso {
  final String id;
  final String titulo;
  final String conteudo;
  final String tipo; // info | alerta | importante | bjj_news
  final String? linkUrl;
  final String? fonte;
  final bool ativo;
  final String? createdAt;

  const Aviso({
    required this.id,
    required this.titulo,
    required this.conteudo,
    this.tipo = 'info',
    this.linkUrl,
    this.fonte,
    this.ativo = true,
    this.createdAt,
  });

  factory Aviso.fromMap(Map<String, dynamic> m) => Aviso(
        id: m['id'],
        titulo: m['titulo'],
        conteudo: m['conteudo'],
        tipo: m['tipo'] ?? 'info',
        linkUrl: m['link_url'],
        fonte: m['fonte'],
        ativo: (m['ativo'] is bool ? m['ativo'] : (m['ativo'] ?? 1) == 1),
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'conteudo': conteudo,
        'tipo': tipo,
        'link_url': linkUrl,
        'fonte': fonte,
        'ativo': ativo,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
      };
}

