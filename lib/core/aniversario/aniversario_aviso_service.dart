import 'package:shared_preferences/shared_preferences.dart';

/// Lembrete local de aniversariantes da turma (sem push).
class AniversarioAvisoService {
  static const _key = 'aniversario_aviso_visto_em';

  String _hojeKey() {
    final hoje = DateTime.now();
    return '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
  }

  Future<bool> avisoPendente(int quantidade) async {
    if (quantidade <= 0) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) != _hojeKey();
  }

  Future<void> marcarVistoHoje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _hojeKey());
  }
}
