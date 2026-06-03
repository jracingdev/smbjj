import '../core/supabase_service.dart';
import '../models/mensalidade.dart';

class MensalidadeRepository {
  Future<List<Mensalidade>> listar({int? mes, int? ano}) async {
    var q = supabase.from('mensalidades').select();
    if (mes != null) q = q.eq('mes', mes);
    if (ano != null) q = q.eq('ano', ano);
    final data = await q.order('aluno_nome');
    return (data as List).map((m) => Mensalidade.fromMap(m)).toList();
  }

  Future<List<Mensalidade>> porAluno(String alunoId) async {
    final data = await supabase.from('mensalidades').select()
        .eq('aluno_id', alunoId).order('ano', ascending: false).order('mes', ascending: false);
    return (data as List).map((m) => Mensalidade.fromMap(m)).toList();
  }

  Future<Mensalidade> criar(Mensalidade m) async {
    final map = m.toMap()..remove('id');
    final data = await supabase.from('mensalidades').insert(map).select().single();
    return Mensalidade.fromMap(data);
  }

  Future<void> atualizar(Mensalidade m) async {
    final map = m.toMap()..remove('id');
    await supabase.from('mensalidades').update(map).eq('id', m.id);
  }

  Future<void> marcarPago(String id) async {
    await supabase.from('mensalidades').update({
      'status': 'pago',
      'data_pagamento': DateTime.now().toIso8601String().split('T')[0],
    }).eq('id', id);
  }

  Future<void> deletar(String id) async {
    await supabase.from('mensalidades').delete().eq('id', id);
  }
}
