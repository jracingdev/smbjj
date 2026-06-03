import '../core/supabase_service.dart';
import '../models/aluno.dart';

class AlunoRepository {
  Future<List<Aluno>> listar({bool? ativo}) async {
    var query = supabase.from('alunos').select();
    if (ativo != null) {
      final data = await query.eq('ativo', ativo).order('nome');
      return (data as List).map((m) => Aluno.fromMap(m)).toList();
    }
    final data = await query.order('nome');
    return (data as List).map((m) => Aluno.fromMap(m)).toList();
  }

  Future<Aluno?> buscarPorEmail(String email) async {
    final data = await supabase.from('alunos').select().eq('email', email).maybeSingle();
    return data != null ? Aluno.fromMap(data) : null;
  }

  Future<Aluno?> buscarPorId(String id) async {
    final data = await supabase.from('alunos').select().eq('id', id).maybeSingle();
    return data != null ? Aluno.fromMap(data) : null;
  }

  Future<Aluno> criar(Aluno aluno) async {
    final map = aluno.toMap()..remove('id');
    final data = await supabase.from('alunos').insert(map).select().single();
    return Aluno.fromMap(data);
  }

  Future<void> atualizar(Aluno aluno) async {
    final map = aluno.toMap()..remove('id');
    map['updated_at'] = DateTime.now().toIso8601String();
    await supabase.from('alunos').update(map).eq('id', aluno.id);
  }

  Future<void> deletar(String id) async {
    await supabase.from('alunos').delete().eq('id', id);
  }

  Future<void> validar(String id) async {
    await supabase.from('alunos').update({
      'cadastro_validado': true, 'ativo': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Aluno>> pendentesValidacao() async {
    final data = await supabase.from('alunos').select()
        .eq('cadastro_validado', false).order('created_at', ascending: false);
    return (data as List).map((m) => Aluno.fromMap(m)).toList();
  }
}
