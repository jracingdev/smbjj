import 'package:shared_preferences/shared_preferences.dart';

/// Lembrete mensal do quadro de aniversariantes (sem push).
class AniversarioMesAvisoService {
  static const _key = 'aniversario_mes_aviso_visto';

  String _mesKey() {
    final hoje = DateTime.now();
    return '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}';
  }

  Future<bool> avisoPendente(int quantidade) async {
    if (quantidade <= 0) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) != _mesKey();
  }

  Future<void> marcarVistoMes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mesKey());
  }
}
