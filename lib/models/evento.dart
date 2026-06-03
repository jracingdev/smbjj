class Evento {
  final String id;
  final String titulo;
  final String data; // yyyy-MM-dd
  final String tipo; // campeonato | seminario | aulao | graduacao | bjj_news | outro
  final String? descricao;
  final String? local;
  final String? organizador;
  final String? linkUrl;
  final String? createdAt;

  const Evento({
    required this.id,
    required this.titulo,
    required this.data,
    this.tipo = 'campeonato',
    this.descricao,
    this.local,
    this.organizador,
    this.linkUrl,
    this.createdAt,
  });

  factory Evento.fromMap(Map<String, dynamic> m) => Evento(
        id: m['id'],
        titulo: m['titulo'],
        data: m['data'],
        tipo: m['tipo'] ?? 'campeonato',
        descricao: m['descricao'],
        local: m['local'],
        organizador: m['organizador'],
        linkUrl: m['link_url'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'data': data,
        'tipo': tipo,
        'descricao': descricao,
        'local': local,
        'organizador': organizador,
        'link_url': linkUrl,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
      };
}
