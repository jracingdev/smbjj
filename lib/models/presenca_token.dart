class PresencaToken {
  final String token;
  final String tipo;
  final String? turmaId;
  final String dataAula;
  final DateTime validoAte;

  const PresencaToken({
    required this.token,
    required this.tipo,
    this.turmaId,
    required this.dataAula,
    required this.validoAte,
  });

  factory PresencaToken.fromRpc(Map<String, dynamic> m) => PresencaToken(
        token: m['token'] as String,
        tipo: m['tipo'] as String,
        turmaId: m['turma_id'] as String?,
        dataAula: m['data_aula'] as String,
        validoAte: DateTime.parse(m['valido_ate'] as String),
      );

  bool get expirado => DateTime.now().isAfter(validoAte);
}

class CheckinResult {
  final bool ok;
  final String turmaNome;
  final String dataAula;
  final String alunoNome;

  const CheckinResult({
    required this.ok,
    required this.turmaNome,
    required this.dataAula,
    required this.alunoNome,
  });

  factory CheckinResult.fromRpc(Map<String, dynamic> m) => CheckinResult(
        ok: m['ok'] == true,
        turmaNome: m['turma_nome'] as String? ?? '',
        dataAula: m['data_aula'] as String? ?? '',
        alunoNome: m['aluno_nome'] as String? ?? '',
      );
}
