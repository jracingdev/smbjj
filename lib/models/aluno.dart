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
        cadastroValidado: (m['cadastro_validado'] is bool ? m['cadastro_validado'] : (m['cadastro_validado'] ?? 0) == 1),
        createdAt: m['created_at'],
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
      };

  Aluno copyWith({
    String? nome, String? email, String? dataNascimento, String? sexo,
    String? telefone, String? nomeResponsavel, String? telefoneResponsavel,
    String? endereco, String? cidade, String? estado, String? cep,
    String? faixa, int? grau, double? peso, String? fotoUrl,
    bool? ativo, bool? cadastroValidado,
  }) => Aluno(
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
      );
}

