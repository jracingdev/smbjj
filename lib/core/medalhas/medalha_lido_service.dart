import 'package:shared_preferences/shared_preferences.dart';
import '../../models/medalha.dart';

/// Controle local de atualizações do quadro de medalhas (sem push).
class MedalhaLidoService {
  static const _key = 'medalhas_visto_em';

  Future<DateTime?> ultimaVisualizacao() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> marcarComoVisto({DateTime? em}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, (em ?? DateTime.now()).toIso8601String());
  }

  DateTime? _parseMedalhaTs(Medalha m) {
    final raw = m.createdAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> temAtualizacao(List<Medalha> medalhas) async {
    final visto = await ultimaVisualizacao();
    if (visto == null) return medalhas.any((m) => m.ativo);
    return medalhas.any((m) {
      if (!m.ativo) return false;
      final ts = _parseMedalhaTs(m);
      if (ts == null) return false;
      return ts.isAfter(visto);
    });
  }

  Future<int> contarNovas(List<Medalha> medalhas) async {
    final visto = await ultimaVisualizacao();
    if (visto == null) return medalhas.where((m) => m.ativo).length;
    return medalhas.where((m) {
      if (!m.ativo) return false;
      final ts = _parseMedalhaTs(m);
      if (ts == null) return false;
      return ts.isAfter(visto);
    }).length;
  }
}
