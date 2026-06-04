import '../core/supabase_errors.dart';
import '../core/supabase_service.dart';
import '../models/turma.dart';

class TurmaRepository {
  Future<List<Turma>> listar({bool apenasAtivas = true}) async {
    var query = supabase.from('turmas').select();
    if (apenasAtivas) query = query.eq('ativa', true);
    final data = await query.order('horario').order('nome');
    return (data as List).map((m) => Turma.fromMap(m)).toList();
  }

  Future<Turma?> buscarPorId(String id) async {
    final data = await supabase.from('turmas').select().eq('id', id).maybeSingle();
    return data != null ? Turma.fromMap(data) : null;
  }

  Future<void> atualizar(Turma turma) async {
    await supabase.from('turmas').update({
      'nome': turma.nome,
      'horario': turma.horario,
      'dias_semana': turma.diasSemana,
      'tipo': turma.tipo,
      'ativa': turma.ativa,
    }).eq('id', turma.id);
  }

  Future<List<Turma>> turmasDoAluno(String alunoId) async {
    final data = await supabase
        .from('aluno_turmas')
        .select('turma_id, turmas(*)')
        .eq('aluno_id', alunoId);
    final turmas = <Turma>[];
    for (final row in data as List) {
      final t = row['turmas'];
      if (t != null) turmas.add(Turma.fromMap(t as Map<String, dynamic>));
    }
    turmas.sort((a, b) => a.horario.compareTo(b.horario));
    return turmas;
  }

  Future<List<String>> alunoIdsPorTurma(String turmaId) async {
    final data = await supabase.from('aluno_turmas').select('aluno_id').eq('turma_id', turmaId);
    return (data as List).map((r) => r['aluno_id'] as String).toList();
  }

  /// Uma única consulta — evita N+1 ao listar alunos.
  Future<Map<String, List<Turma>>> turmasPorTodosAlunos() async {
    final data = await comTimeout(
      supabase.from('aluno_turmas').select('aluno_id, turmas(*)'),
    );
    final map = <String, List<Turma>>{};
    for (final row in data as List) {
      final alunoId = row['aluno_id'] as String;
      final t = row['turmas'];
      if (t == null) continue;
      map.putIfAbsent(alunoId, () => []).add(Turma.fromMap(t as Map<String, dynamic>));
    }
    for (final lista in map.values) {
      lista.sort((a, b) => a.horario.compareTo(b.horario));
    }
    return map;
  }

  /// Mapa turma_id → lista de aluno_id em uma consulta (painel financeiro).
  Future<Map<String, List<String>>> alunoIdsPorTodasTurmas() async {
    final data = await comTimeout(
      supabase.from('aluno_turmas').select('aluno_id, turma_id'),
    );
    final map = <String, List<String>>{};
    for (final row in data as List) {
      final tid = row['turma_id'] as String;
      final aid = row['aluno_id'] as String;
      map.putIfAbsent(tid, () => []).add(aid);
    }
    return map;
  }

  Future<void> substituirTurmasAluno(String alunoId, List<String> turmaIds) async {
    await supabase.from('aluno_turmas').delete().eq('aluno_id', alunoId);
    if (turmaIds.isEmpty) return;
    final hoje = DateTime.now().toIso8601String().substring(0, 10);
    await supabase.from('aluno_turmas').insert(
      turmaIds.map((tid) => {
        'aluno_id': alunoId,
        'turma_id': tid,
        'data_inicio': hoje,
      }).toList(),
    );
  }
}
