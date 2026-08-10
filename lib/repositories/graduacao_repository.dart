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

  /// Faixas-pretas da academia (Black Belt Legacy).
  ///
  /// Regra: todas as graduações com `faixa == 'preta'` (não só `formada_academia`).
  /// Um registro por aluno — o de maior grau; em empate, a data mais recente.
  /// O badge “Formado(a) na casa” continua vindo de `formada_academia` na UI.
  Future<List<Graduacao>> listarPretasAcademia() async {
    final data = await supabase
        .from('graduacoes')
        .select()
        .eq('faixa', 'preta')
        .order('data_graduacao', ascending: false);
    final todas = (data as List).map((m) => Graduacao.fromMap(m)).toList();
    final porAluno = <String, Graduacao>{};
    for (final g in todas) {
      final atual = porAluno[g.alunoId];
      if (atual == null) {
        porAluno[g.alunoId] = g;
        continue;
      }
      if (g.grau > atual.grau) {
        porAluno[g.alunoId] = g;
      } else if (g.grau == atual.grau &&
          g.dataGraduacao.compareTo(atual.dataGraduacao) > 0) {
        porAluno[g.alunoId] = g;
      }
    }
    final lista = porAluno.values.toList()
      ..sort((a, b) {
        final porData = b.dataGraduacao.compareTo(a.dataGraduacao);
        if (porData != 0) return porData;
        return a.alunoNome.toLowerCase().compareTo(b.alunoNome.toLowerCase());
      });
    return lista;
  }

  /// Compat: mesmo quadro Legacy (todas as pretas da academia).
  Future<List<Graduacao>> listarPretasFormadas() => listarPretasAcademia();

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
