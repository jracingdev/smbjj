class Medalha {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String titulo;
  final String tipo;
  final String? dataConquista;
  final bool ativo;
  final String? createdAt;

  const Medalha({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.titulo,
    this.tipo = 'ouro',
    this.dataConquista,
    this.ativo = true,
    this.createdAt,
  });

  factory Medalha.fromMap(Map<String, dynamic> m) => Medalha(
        id: m['id'].toString(),
        alunoId: m['aluno_id']?.toString() ?? '',
        alunoNome: (m['aluno_nome'] as String?)?.trim() ?? '',
        titulo: m['titulo'] as String,
        tipo: m['tipo'] as String? ?? 'ouro',
        dataConquista: m['data_conquista'] as String?,
        ativo: m['ativo'] != false,
        createdAt: m['created_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'aluno_nome': alunoNome,
        'titulo': titulo,
        'tipo': tipo,
        'data_conquista': dataConquista,
        'ativo': ativo,
      };

  Medalha copyWith({
    String? alunoNome,
    String? titulo,
    String? tipo,
    String? dataConquista,
    bool? ativo,
  }) =>
      Medalha(
        id: id,
        alunoId: alunoId,
        alunoNome: alunoNome ?? this.alunoNome,
        titulo: titulo ?? this.titulo,
        tipo: tipo ?? this.tipo,
        dataConquista: dataConquista ?? this.dataConquista,
        ativo: ativo ?? this.ativo,
        createdAt: createdAt,
      );
}
