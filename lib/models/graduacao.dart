class Graduacao {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String dataGraduacao;
  final String faixa;
  final int grau;
  final String? observacao;
  final String? professor;
  final String? evento;
  final bool formadaAcademia;
  final String? createdAt;

  const Graduacao({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.dataGraduacao,
    required this.faixa,
    this.grau = 0,
    this.observacao,
    this.professor,
    this.evento,
    this.formadaAcademia = false,
    this.createdAt,
  });

  bool get isPretaFormadaCasa => formadaAcademia && faixa == 'preta';

  factory Graduacao.fromMap(Map<String, dynamic> m) => Graduacao(
        id: m['id'].toString(),
        alunoId: m['aluno_id']?.toString() ?? '',
        alunoNome: (m['aluno_nome'] as String?)?.trim() ?? '',
        dataGraduacao: (m['data_graduacao'] as String?)?.trim() ?? '',
        faixa: (m['faixa'] as String?)?.trim() ?? 'branca',
        grau: (m['grau'] as num?)?.toInt() ?? 0,
        observacao: m['observacao'] as String?,
        professor: m['professor'] as String?,
        evento: m['evento'] as String?,
        formadaAcademia: m['formada_academia'] == true,
        createdAt: m['created_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'aluno_nome': alunoNome,
        'data_graduacao': dataGraduacao,
        'faixa': faixa,
        'grau': grau,
        'observacao': observacao,
        'professor': professor,
        'evento': evento,
        'formada_academia': formadaAcademia && faixa == 'preta',
        'updated_at': DateTime.now().toIso8601String(),
      };

  Graduacao copyWith({
    String? alunoNome,
    String? dataGraduacao,
    String? faixa,
    int? grau,
    String? observacao,
    String? professor,
    String? evento,
    bool? formadaAcademia,
  }) =>
      Graduacao(
        id: id,
        alunoId: alunoId,
        alunoNome: alunoNome ?? this.alunoNome,
        dataGraduacao: dataGraduacao ?? this.dataGraduacao,
        faixa: faixa ?? this.faixa,
        grau: grau ?? this.grau,
        observacao: observacao ?? this.observacao,
        professor: professor ?? this.professor,
        evento: evento ?? this.evento,
        formadaAcademia: formadaAcademia ?? this.formadaAcademia,
        createdAt: createdAt,
      );
}
