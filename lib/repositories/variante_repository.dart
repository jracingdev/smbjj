import '../core/supabase_service.dart';
import '../models/produto_variante.dart';

class VarianteRepository {
  Future<List<ProdutoVariante>> porProduto(String produtoId) async {
    final data = await supabase.from('produto_variantes').select().eq('produto_id', produtoId);
    return (data as List).map((m) => ProdutoVariante.fromMap(m)).toList();
  }

  Future<int> estoqueTotal(String produtoId) async {
    final lista = await porProduto(produtoId);
    return lista.fold<int>(0, (s, v) => s + v.estoque);
  }

  Future<void> sincronizar(String produtoId, List<ProdutoVariante> variantes) async {
    await supabase.from('produto_variantes').delete().eq('produto_id', produtoId);
    if (variantes.isEmpty) return;
    final maps = variantes.map((v) {
      final m = v.toMap()..remove('id');
      m['produto_id'] = produtoId;
      return m;
    }).toList();
    await supabase.from('produto_variantes').insert(maps);
  }

  Future<void> deletar(String id) async {
    await supabase.from('produto_variantes').delete().eq('id', id);
  }

  Future<void> deletarPorProduto(String produtoId) async {
    await supabase.from('produto_variantes').delete().eq('produto_id', produtoId);
  }
}
