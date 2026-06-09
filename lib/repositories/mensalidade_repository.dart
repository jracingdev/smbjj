import '../core/mp_service.dart';
import '../core/supabase_errors.dart';
import '../core/supabase_service.dart';
import '../models/mensalidade.dart';

class MensalidadeRepository {
  Future<List<Mensalidade>> listar({int? mes, int? ano, bool incluirCanceladas = false}) async {
    var q = supabase.from('mensalidades').select();
    if (mes != null) q = q.eq('mes', mes);
    if (ano != null) q = q.eq('ano', ano);
    final data = await comTimeout(q.order('aluno_nome'));
    var lista = (data as List).map((m) => Mensalidade.fromMap(m)).toList();
    if (!incluirCanceladas) {
      lista = lista.where((m) => !m.cancelada).toList();
    }
    return lista;
  }

  Future<List<Mensalidade>> porAluno(String alunoId) async {
    final data = await comTimeout(
      supabase.from('mensalidades').select().eq('aluno_id', alunoId).order('ano', ascending: false).order('mes', ascending: false),
    );
    return (data as List).map((m) => Mensalidade.fromMap(m)).toList();
  }

  Future<bool> existeMesAno(String alunoId, int mes, int ano) async {
    final data = await comTimeout(
      supabase
          .from('mensalidades')
          .select('id')
          .eq('aluno_id', alunoId)
          .eq('mes', mes)
          .eq('ano', ano)
          .eq('cancelada', false)
          .maybeSingle(),
    );
    return data != null;
  }

  Future<Mensalidade> criar(Mensalidade m) async {
    final map = m.toMap()..remove('id');
    final data = await comTimeout(supabase.from('mensalidades').insert(map).select().single());
    return Mensalidade.fromMap(data);
  }

  Future<void> atualizar(Mensalidade m) async {
    final map = m.toMap()..remove('id');
    await comTimeout(supabase.from('mensalidades').update(map).eq('id', m.id));
  }

  Future<void> marcarPago(String id) async {
    await comTimeout(supabase.from('mensalidades').update({
      'status': 'pago',
      'data_pagamento': DateTime.now().toIso8601String().split('T')[0],
      'mp_preferencia_id': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id));
  }

  Future<void> limparPreferenciaMp(String id) async {
    await comTimeout(supabase.from('mensalidades').update({
      'mp_preferencia_id': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id));
  }

  Future<void> salvarPreferenciaId(String id, String preferenciaId) async {
    await comTimeout(supabase.from('mensalidades').update({
      'mp_preferencia_id': preferenciaId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id));
  }

  /// Consulta o MP para todas as mensalidades pendentes com preference_id salvo
  /// e marca como pagas as que retornarem status 'approved'.
  /// Retorna a quantidade de mensalidades marcadas automaticamente.
  Future<int> sincronizarStatusMP() async {
    final token = await MercadoPagoService.instance.getAccessToken();
    if (token == null || token.isEmpty) return 0;

    final data = await comTimeout(
      supabase
          .from('mensalidades')
          .select()
          .eq('status', 'pendente')
          .eq('cancelada', false)
          .not('mp_preferencia_id', 'is', null),
    );
    final pendentes = (data as List).map((m) => Mensalidade.fromMap(m)).toList();
    if (pendentes.isEmpty) return 0;

    int marcadas = 0;
    await Future.wait(pendentes.map((m) async {
      if (m.status == 'pago') return;
      final status = await MercadoPagoService.instance.consultarStatus(m.mpPreferenciaId!);
      if (status == 'approved') {
        await marcarPago(m.id);
        marcadas++;
      }
    }));
    return marcadas;
  }

  Future<void> deletar(String id) async {
    await comTimeout(supabase.from('mensalidades').delete().eq('id', id));
  }

  /// Cancela mensalidades futuras (pendentes) após interrupção de cobrança.
  Future<void> cancelarFuturas({
    required String alunoId,
    required int aPartirMes,
    required int aPartirAno,
    required String justificativa,
  }) async {
    final data = await comTimeout(
      supabase
          .from('mensalidades')
          .select()
          .eq('aluno_id', alunoId)
          .eq('status', 'pendente')
          .gte('ano', aPartirAno),
    );
    for (final row in data as List) {
      final m = Mensalidade.fromMap(row);
      if (m.cancelada) continue;
      final depois = m.ano > aPartirAno || (m.ano == aPartirAno && m.mes >= aPartirMes);
      if (!depois) continue;
      await atualizar(m.copyWith(
        cancelada: true,
        observacao: 'Cancelada: $justificativa',
      ));
    }
  }
}
