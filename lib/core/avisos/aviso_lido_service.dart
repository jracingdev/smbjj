import 'package:shared_preferences/shared_preferences.dart';
import '../../models/aviso.dart';

/// Controle local de avisos já visualizados (sem push).
class AvisoLidoService {
  static const _key = 'avisos_lidos_ids';

  Future<Set<String>> idsLidos() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> marcarComoLidos(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final atuais = (prefs.getStringList(_key) ?? []).toSet()..addAll(ids);
    await prefs.setStringList(_key, atuais.toList());
  }

  Future<int> contarNaoLidos(List<Aviso> avisos) async {
    final lidos = await idsLidos();
    return avisos.where((a) => a.ativo && !lidos.contains(a.id)).length;
  }
}
