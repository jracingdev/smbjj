import '../core/supabase_service.dart';
import '../models/presenca_config.dart';

class PresencaConfigRepository {
  Future<PresencaConfig> obter() async {
    try {
      final data = await supabase.from('presenca_config').select().eq('id', 1).maybeSingle();
      if (data == null) return const PresencaConfig();
      return PresencaConfig.fromMap(data);
    } catch (_) {
      return const PresencaConfig();
    }
  }

  Future<void> salvar(PresencaConfig config) async {
    await supabase.from('presenca_config').upsert({'id': 1, ...config.toMap()});
  }
}
