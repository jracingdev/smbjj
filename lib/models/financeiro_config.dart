import 'regra_financeira.dart';

class FinanceiroConfig {
  final double valorAdulto;
  final double valorMenor;
  final double desconto2oFamiliarPercent;
  final double desconto3oFamiliarPercent;
  final double descontoMesmoPagantePercent;
  final int diaVencimento;
  final List<RegraFinanceira> regrasExtras;

  const FinanceiroConfig({
    this.valorAdulto = 110,
    this.valorMenor = 80,
    this.desconto2oFamiliarPercent = 10,
    this.desconto3oFamiliarPercent = 15,
    this.descontoMesmoPagantePercent = 5,
    this.diaVencimento = 10,
    this.regrasExtras = const [],
  });

  static List<RegraFinanceira> _parseRegras(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => RegraFinanceira.fromMap(Map<String, dynamic>.from(e)))
        .where((r) => r.titulo.isNotEmpty)
        .toList();
  }

  factory FinanceiroConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const FinanceiroConfig();
    return FinanceiroConfig(
      valorAdulto: (m['valor_adulto'] as num?)?.toDouble() ?? 110,
      valorMenor: (m['valor_menor'] as num?)?.toDouble() ?? 80,
      desconto2oFamiliarPercent: (m['desconto_2o_familiar_percent'] as num?)?.toDouble() ?? 10,
      desconto3oFamiliarPercent: (m['desconto_3o_familiar_percent'] as num?)?.toDouble() ?? 15,
      descontoMesmoPagantePercent: (m['desconto_mesmo_pagante_percent'] as num?)?.toDouble() ?? 5,
      diaVencimento: m['dia_vencimento'] as int? ?? 10,
      regrasExtras: _parseRegras(m['regras_extras']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': 1,
        'valor_adulto': valorAdulto,
        'valor_menor': valorMenor,
        'desconto_2o_familiar_percent': desconto2oFamiliarPercent,
        'desconto_3o_familiar_percent': desconto3oFamiliarPercent,
        'desconto_mesmo_pagante_percent': descontoMesmoPagantePercent,
        'dia_vencimento': diaVencimento,
        'regras_extras': regrasExtras.map((r) => r.toMap()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  List<int> get diasWhatsAppExtras => regrasExtras
      .where((r) => r.ativa && r.tipo == 'dia_whatsapp' && r.valor >= 1 && r.valor <= 28)
      .map((r) => r.valor.toInt())
      .toList();
}
