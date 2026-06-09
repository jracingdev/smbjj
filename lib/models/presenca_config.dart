enum MetodoPresenca {
  chamada,
  qrTurma,
  qrUnico;

  static MetodoPresenca fromDb(String? v) => switch (v) {
        'qr_turma' => MetodoPresenca.qrTurma,
        'qr_unico' => MetodoPresenca.qrUnico,
        _ => MetodoPresenca.chamada,
      };

  String get dbValue => switch (this) {
        MetodoPresenca.chamada => 'chamada',
        MetodoPresenca.qrTurma => 'qr_turma',
        MetodoPresenca.qrUnico => 'qr_unico',
      };

  String get label => switch (this) {
        MetodoPresenca.chamada => 'Chamada manual',
        MetodoPresenca.qrTurma => 'QR por turma',
        MetodoPresenca.qrUnico => 'QR único',
      };

  String get descricao => switch (this) {
        MetodoPresenca.chamada => 'Professor marca presença na lista',
        MetodoPresenca.qrTurma => 'QR específico de cada turma',
        MetodoPresenca.qrUnico => 'Um QR para todos — o app detecta a turma do aluno',
      };
}

class PresencaConfig {
  final MetodoPresenca metodo;
  final int tokenValidadeMinutos;

  const PresencaConfig({
    this.metodo = MetodoPresenca.chamada,
    this.tokenValidadeMinutos = 30,
  });

  factory PresencaConfig.fromMap(Map<String, dynamic> m) => PresencaConfig(
        metodo: MetodoPresenca.fromDb(m['metodo'] as String?),
        tokenValidadeMinutos: (m['token_validade_minutos'] as num?)?.toInt() ?? 30,
      );

  Map<String, dynamic> toMap() => {
        'metodo': metodo.dbValue,
        'token_validade_minutos': tokenValidadeMinutos,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
