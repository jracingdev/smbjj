import '../core/supabase_service.dart';
import '../models/graduacao.dart';

class GraduacaoRepository {
  Future<List<Graduacao>> listarPorAluno(String alunoId) async {
    final data = await supabase
        .from('graduacoes')
        .select()
        .eq('aluno_id', alunoId)
        .order('data_graduacao', ascending: false)
        .order('created_at', ascending: false);
    return (data as List).map((m) => Graduacao.fromMap(m)).toList();
  }

  /// Faixas-pretas formadas pela academia (destaque SM BJJ).
  Future<List<Graduacao>> listarPretasFormadas() async {
    final data = await supabase
        .from('graduacoes')
        .select()
        .eq('formada_academia', true)
        .eq('faixa', 'preta')
        .order('data_graduacao', ascending: false);
    return (data as List).map((m) => Graduacao.fromMap(m)).toList();
  }

  Future<Graduacao> criar(Graduacao graduacao) async {
    final map = graduacao.toMap()..remove('id');
    final data = await supabase.from('graduacoes').insert(map).select().single();
    return Graduacao.fromMap(data);
  }

  Future<void> atualizar(Graduacao graduacao) async {
    final map = graduacao.toMap()..remove('id');
    await supabase.from('graduacoes').update(map).eq('id', graduacao.id);
  }

  Future<void> remover(String id) async {
    await supabase.from('graduacoes').delete().eq('id', id);
  }
}
