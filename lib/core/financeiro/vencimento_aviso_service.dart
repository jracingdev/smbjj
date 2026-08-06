import 'package:shared_preferences/shared_preferences.dart';
import '../../models/mensalidade.dart';
import '../../utils/whatsapp_utils.dart';

/// Aviso in-app de vencimento/cobrança para o aluno (sem push).
/// Dispara uma vez por dia/tipo para todos os alunos com pendência.
class VencimentoAvisoService {
  static const _keyPrefix = 'vencimento_aviso_visto_';

  String _hojeKey() {
    final hoje = DateTime.now();
    return '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
  }

  /// Retorna o tipo de cobrança do dia (aviso1/aviso5/vencimento/extra) se houver
  /// mensalidade pendente do mês atual para o aluno; caso contrário null.
  String? tipoPendenteHoje({
    required List<Mensalidade> minhasMensalidades,
    required int diaVencimento,
    List<int> diasExtras = const [],
  }) {
    final hoje = DateTime.now();
    final tipo = tipoCobrancaDoDia(hoje.day, diaVencimento, diasExtras: diasExtras);
    if (tipo == null) return null;
    final temPendente = minhasMensalidades.any(
      (m) =>
          m.mes == hoje.month &&
          m.ano == hoje.year &&
          !m.cancelada &&
          m.status != 'pago',
    );
    return temPendente ? tipo : null;
  }

  Future<bool> avisoPendente(String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$tipo') != _hojeKey();
  }

  Future<void> marcarVisto(String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$tipo', _hojeKey());
  }
}
