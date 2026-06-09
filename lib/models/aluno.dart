class Aluno {
  final String id;
  final String nome;
  final String? email;
  final String? dataNascimento;
  final String sexo;
  final String? telefone;
  final String? nomeResponsavel;
  final String? telefoneResponsavel;
  final String? endereco;
  final String? cidade;
  final String? estado;
  final String? cep;
  final String faixa;
  final int grau;
  final double? peso;
  final String? fotoUrl;
  final bool ativo;
  final bool cadastroValidado;
  final String? createdAt;

  // Financeiro
  final bool bolsista;
  final double percentualBolsa;
  final String? grupoFamiliar;
  final String? cpfPagante;
  final bool cobrancaAtiva;
  final String? dataInicioCobranca;
  final String? dataInterrupcaoCobranca;
  final String? justificativaInterrupcao;
  final double? valorMensalidadeCustom;
  /// Formato YYYY-MM — quando o aluno começou a treinar.
  final String? dataInicioAulas;
  /// Marcado pelo admin — habilita pro-rata no primeiro mês.
  final bool iniciante;
  /// Preferência salva na validação: aplicar pro-rata no 1º mês.
  final bool proRataPrimeiroMes;

  bool get cadastroCompleto =>
      nome.trim().isNotEmpty &&
      dataNascimento != null &&
      dataNascimento!.isNotEmpty &&
      telefone != null &&
      telefone!.trim().isNotEmpty &&
      cidade != null &&
      cidade!.trim().isNotEmpty;

  const Aluno({
    required this.id,
    required this.nome,
    this.email,
    this.dataNascimento,
    this.sexo = 'masculino',
    this.telefone,
    this.nomeResponsavel,
    this.telefoneResponsavel,
    this.endereco,
    this.cidade,
    this.estado,
    this.cep,
    this.faixa = 'branca',
    this.grau = 0,
    this.peso,
    this.fotoUrl,
    this.ativo = true,
    this.cadastroValidado = false,
    this.createdAt,
    this.bolsista = false,
    this.percentualBolsa = 0,
    this.grupoFamiliar,
    this.cpfPagante,
    this.cobrancaAtiva = true,
    this.dataInicioCobranca,
    this.dataInterrupcaoCobranca,
    this.justificativaInterrupcao,
    this.valorMensalidadeCustom,
    this.dataInicioAulas,
    this.iniciante = false,
    this.proRataPrimeiroMes = true,
  });

  factory Aluno.fromMap(Map<String, dynamic> m) => Aluno(
        id: m['id'],
        nome: m['nome'],
        email: m['email'],
        dataNascimento: m['data_nascimento'],
        sexo: m['sexo'] ?? 'masculino',
        telefone: m['telefone'],
        nomeResponsavel: m['nome_responsavel'],
        telefoneResponsavel: m['telefone_responsavel'],
        endereco: m['endereco'],
        cidade: m['cidade'],
        estado: m['estado'],
        cep: m['cep'],
        faixa: m['faixa'] ?? 'branca',
        grau: m['grau'] ?? 0,
        peso: m['peso']?.toDouble(),
        fotoUrl: m['foto_url'],
        ativo: (m['ativo'] is bool ? m['ativo'] : (m['ativo'] ?? 1) == 1),
        cadastroValidado: (m['cadastro_validado'] is bool
            ? m['cadastro_validado']
            : (m['cadastro_validado'] ?? 0) == 1),
        createdAt: m['created_at'],
        bolsista: m['bolsista'] == true,
        percentualBolsa: (m['percentual_bolsa'] as num?)?.toDouble() ?? 0,
        grupoFamiliar: m['grupo_familiar'] as String?,
        cpfPagante: m['cpf_pagante'] as String?,
        cobrancaAtiva: m['cobranca_ativa'] != false,
        dataInicioCobranca: m['data_inicio_cobranca'] as String?,
        dataInterrupcaoCobranca: m['data_interrupcao_cobranca'] as String?,
        justificativaInterrupcao: m['justificativa_interrupcao'] as String?,
        valorMensalidadeCustom: (m['valor_mensalidade_custom'] as num?)?.toDouble(),
        dataInicioAulas: m['data_inicio_aulas'] as String?,
        iniciante: m['iniciante'] == true,
        proRataPrimeiroMes: m['pro_rata_primeiro_mes'] != false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'data_nascimento': dataNascimento,
        'sexo': sexo,
        'telefone': telefone,
        'nome_responsavel': nomeResponsavel,
        'telefone_responsavel': telefoneResponsavel,
        'endereco': endereco,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
        'faixa': faixa,
        'grau': grau,
        'peso': peso,
        'foto_url': fotoUrl,
        'ativo': ativo,
        'cadastro_validado': cadastroValidado,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'bolsista': bolsista,
        'percentual_bolsa': percentualBolsa,
        'grupo_familiar': grupoFamiliar,
        'cpf_pagante': cpfPagante,
        'cobranca_ativa': cobrancaAtiva,
        'data_inicio_cobranca': dataInicioCobranca,
        'data_interrupcao_cobranca': dataInterrupcaoCobranca,
        'justificativa_interrupcao': justificativaInterrupcao,
        'valor_mensalidade_custom': valorMensalidadeCustom,
        'data_inicio_aulas': dataInicioAulas,
        'iniciante': iniciante,
        'pro_rata_primeiro_mes': proRataPrimeiroMes,
      };

  Aluno copyWith({
    String? nome,
    String? email,
    String? dataNascimento,
    String? sexo,
    String? telefone,
    String? nomeResponsavel,
    String? telefoneResponsavel,
    String? endereco,
    String? cidade,
    String? estado,
    String? cep,
    String? faixa,
    int? grau,
    double? peso,
    String? fotoUrl,
    bool? ativo,
    bool? cadastroValidado,
    bool? bolsista,
    double? percentualBolsa,
    String? grupoFamiliar,
    String? cpfPagante,
    bool? cobrancaAtiva,
    String? dataInicioCobranca,
    String? dataInterrupcaoCobranca,
    String? justificativaInterrupcao,
    double? valorMensalidadeCustom,
    String? dataInicioAulas,
    bool? iniciante,
    bool? proRataPrimeiroMes,
  }) =>
      Aluno(
        id: id,
        nome: nome ?? this.nome,
        email: email ?? this.email,
        dataNascimento: dataNascimento ?? this.dataNascimento,
        sexo: sexo ?? this.sexo,
        telefone: telefone ?? this.telefone,
        nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
        telefoneResponsavel: telefoneResponsavel ?? this.telefoneResponsavel,
        endereco: endereco ?? this.endereco,
        cidade: cidade ?? this.cidade,
        estado: estado ?? this.estado,
        cep: cep ?? this.cep,
        faixa: faixa ?? this.faixa,
        grau: grau ?? this.grau,
        peso: peso ?? this.peso,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        ativo: ativo ?? this.ativo,
        cadastroValidado: cadastroValidado ?? this.cadastroValidado,
        createdAt: createdAt,
        bolsista: bolsista ?? this.bolsista,
        percentualBolsa: percentualBolsa ?? this.percentualBolsa,
        grupoFamiliar: grupoFamiliar ?? this.grupoFamiliar,
        cpfPagante: cpfPagante ?? this.cpfPagante,
        cobrancaAtiva: cobrancaAtiva ?? this.cobrancaAtiva,
        dataInicioCobranca: dataInicioCobranca ?? this.dataInicioCobranca,
        dataInterrupcaoCobranca: dataInterrupcaoCobranca ?? this.dataInterrupcaoCobranca,
        justificativaInterrupcao: justificativaInterrupcao ?? this.justificativaInterrupcao,
        valorMensalidadeCustom: valorMensalidadeCustom ?? this.valorMensalidadeCustom,
        dataInicioAulas: dataInicioAulas ?? this.dataInicioAulas,
        iniciante: iniciante ?? this.iniciante,
        proRataPrimeiroMes: proRataPrimeiroMes ?? this.proRataPrimeiroMes,
      );
}
