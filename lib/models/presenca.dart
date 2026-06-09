class Presenca {
  final String id;
  final String turmaId;
  final String alunoId;
  final String alunoNome;
  final String dataAula;
  final bool presente;
  final String? observacao;
  final String? createdAt;

  const Presenca({
    required this.id,
    required this.turmaId,
    required this.alunoId,
    required this.alunoNome,
    required this.dataAula,
    this.presente = true,
    this.observacao,
    this.createdAt,
  });

  factory Presenca.fromMap(Map<String, dynamic> m) => Presenca(
        id: m['id'] as String,
        turmaId: m['turma_id'] as String,
        alunoId: m['aluno_id'] as String,
        alunoNome: m['aluno_nome'] as String,
        dataAula: m['data_aula'] as String,
        presente: m['presente'] != false,
        observacao: m['observacao'] as String?,
        createdAt: m['created_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'turma_id': turmaId,
        'aluno_id': alunoId,
        'aluno_nome': alunoNome,
        'data_aula': dataAula,
        'presente': presente,
        'observacao': observacao,
      };
}
