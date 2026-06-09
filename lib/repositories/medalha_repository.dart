import '../core/supabase_service.dart';
import '../models/medalha.dart';

class MedalhaRepository {
  Future<List<Medalha>> listar({bool apenasAtivas = true}) async {
    var query = supabase.from('medalhas').select();
    if (apenasAtivas) query = query.eq('ativo', true);
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((m) => Medalha.fromMap(m)).toList();
  }

  Future<void> criar(Medalha medalha) async {
    final map = medalha.toMap()..remove('id');
    await supabase.from('medalhas').insert(map);
  }

  Future<void> atualizar(Medalha medalha) async {
    final map = medalha.toMap()..remove('id');
    await supabase.from('medalhas').update(map).eq('id', medalha.id);
  }

  Future<void> remover(String id) async {
    await supabase.from('medalhas').delete().eq('id', id);
  }
}
