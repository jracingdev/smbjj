import '../core/supabase_service.dart';
import '../models/aviso.dart';

class AvisoRepository {
  Future<List<Aviso>> listar({bool? apenasAtivos}) async {
    if (apenasAtivos == true) {
      final data = await supabase.from('avisos').select().eq('ativo', true).order('created_at', ascending: false);
      return (data as List).map((m) => Aviso.fromMap(m)).toList();
    }
    final data = await supabase.from('avisos').select().order('created_at', ascending: false);
    return (data as List).map((m) => Aviso.fromMap(m)).toList();
  }

  Future<Aviso> criar(Aviso a) async {
    final map = a.toMap()..remove('id');
    final data = await supabase.from('avisos').insert(map).select().single();
    return Aviso.fromMap(data);
  }

  Future<void> atualizar(Aviso a) async {
    final map = a.toMap()..remove('id');
    await supabase.from('avisos').update(map).eq('id', a.id);
  }

  Future<void> deletar(String id) async {
    await supabase.from('avisos').delete().eq('id', id);
  }
}
