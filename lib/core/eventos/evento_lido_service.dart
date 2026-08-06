import 'package:shared_preferences/shared_preferences.dart';
import '../../models/evento.dart';

/// Controle local de eventos/campeonatos já visualizados (sem push).
class EventoLidoService {
  static const _key = 'eventos_lidos_ids';

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

  Future<int> contarNaoLidos(List<Evento> eventos) async {
    final hoje = DateTime.now();
    final hojeIso =
        '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
    final lidos = await idsLidos();
    return eventos.where((e) => e.data.compareTo(hojeIso) >= 0 && !lidos.contains(e.id)).length;
  }
}
