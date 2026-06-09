import 'dart:convert';

class Turma {
  final String id;
  final String nome;
  final String horario;
  final List<String> diasSemana;
  final String tipo;
  final bool ativa;

  const Turma({
    required this.id,
    required this.nome,
    required this.horario,
    this.diasSemana = const [],
    this.tipo = 'mista',
    this.ativa = true,
  });

  factory Turma.fromMap(Map<String, dynamic> m) {
    List<String> dias = [];
    final raw = m['dias_semana'];
    if (raw is String && raw.isNotEmpty) {
      try {
        dias = List<String>.from(jsonDecode(raw) as List);
      } catch (_) {
        dias = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    } else if (raw is List) {
      dias = raw.map((e) => e.toString()).toList();
    }
    return Turma(
      id: m['id'] as String,
      nome: m['nome'] as String,
      horario: m['horario'] as String,
      diasSemana: dias,
      tipo: m['tipo'] as String? ?? 'mista',
      ativa: _parseAtiva(m['ativa']),
    );
  }

  static bool _parseAtiva(dynamic v) {
    if (v == null) return true;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == 'true' || v == '1';
    return true;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'horario': horario,
        'dias_semana': diasSemana,
        'tipo': tipo,
        'ativa': ativa,
      };

  Turma copyWith({
    String? nome,
    String? horario,
    List<String>? diasSemana,
    String? tipo,
    bool? ativa,
  }) =>
      Turma(
        id: id,
        nome: nome ?? this.nome,
        horario: horario ?? this.horario,
        diasSemana: diasSemana ?? this.diasSemana,
        tipo: tipo ?? this.tipo,
        ativa: ativa ?? this.ativa,
      );
}
