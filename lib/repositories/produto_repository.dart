import '../core/supabase_service.dart';
import '../models/produto.dart';

class ProdutoRepository {
  Future<List<Produto>> listar({bool? ativo}) async {
    if (ativo != null) {
      final data = await supabase.from('produtos').select().eq('ativo', ativo).order('nome');
      return (data as List).map((m) => Produto.fromMap(m)).toList();
    }
    final data = await supabase.from('produtos').select().order('nome');
    return (data as List).map((m) => Produto.fromMap(m)).toList();
  }

  Future<Produto> criar(Produto p) async {
    final map = p.toMap()..remove('id');
    final data = await supabase.from('produtos').insert(map).select().single();
    return Produto.fromMap(data);
  }

  Future<void> atualizar(Produto p) async {
    final map = p.toMap()..remove('id');
    await supabase.from('produtos').update(map).eq('id', p.id);
  }

  Future<void> deletar(String id) async {
    await supabase.from('produtos').delete().eq('id', id);
  }
}
