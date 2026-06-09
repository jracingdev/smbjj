import '../core/supabase_service.dart';
import '../models/presenca.dart';

class PresencaRepository {
  Future<List<Presenca>> porTurmaEData(String turmaId, String dataIso) async {
    final data = await supabase
        .from('presencas')
        .select()
        .eq('turma_id', turmaId)
        .eq('data_aula', dataIso)
        .order('aluno_nome');
    return (data as List).map((m) => Presenca.fromMap(m)).toList();
  }

  Future<List<Presenca>> porAluno(String alunoId, {int limite = 30}) async {
    final data = await supabase
        .from('presencas')
        .select()
        .eq('aluno_id', alunoId)
        .order('data_aula', ascending: false)
        .limit(limite);
    return (data as List).map((m) => Presenca.fromMap(m)).toList();
  }

  Future<int> contarPresencasMes(String alunoId, int mes, int ano) async {
    final prefixo = '$ano-${mes.toString().padLeft(2, '0')}';
    final data = await supabase
        .from('presencas')
        .select('id')
        .eq('aluno_id', alunoId)
        .eq('presente', true)
        .like('data_aula', '$prefixo%');
    return (data as List).length;
  }

  /// Salva ou atualiza a chamada de uma turma em uma data.
  Future<void> salvarChamada({
    required String turmaId,
    required String dataIso,
    required Map<String, ({String nome, bool presente})> porAluno,
  }) async {
    if (porAluno.isEmpty) return;
    final rows = porAluno.entries
        .map((e) => {
              'turma_id': turmaId,
              'aluno_id': e.key,
              'aluno_nome': e.value.nome,
              'data_aula': dataIso,
              'presente': e.value.presente,
            })
        .toList();
    await supabase.from('presencas').upsert(rows, onConflict: 'turma_id,aluno_id,data_aula');
  }

  Future<void> remover(String id) async {
    await supabase.from('presencas').delete().eq('id', id);
  }
}
