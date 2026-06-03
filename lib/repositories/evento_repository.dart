import '../core/supabase_service.dart';
import '../models/evento.dart';

class EventoRepository {
  Future<List<Evento>> listar() async {
    final data = await supabase.from('eventos').select().order('data');
    return (data as List).map((m) => Evento.fromMap(m)).toList();
  }

  Future<Evento> criar(Evento e) async {
    final map = e.toMap()..remove('id');
    final data = await supabase.from('eventos').insert(map).select().single();
    return Evento.fromMap(data);
  }

  Future<void> atualizar(Evento e) async {
    final map = e.toMap()..remove('id');
    await supabase.from('eventos').update(map).eq('id', e.id);
  }

  Future<void> deletar(String id) async {
    await supabase.from('eventos').delete().eq('id', id);
  }
}
