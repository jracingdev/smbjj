import '../core/supabase_service.dart';
import '../models/presenca_token.dart';

class PresencaCheckinRepository {
  Future<PresencaToken> criarToken({
    required String tipo,
    String? turmaId,
  }) async {
    final data = await supabase.rpc('criar_token_presenca', params: {
      'p_tipo': tipo,
      'p_turma_id': turmaId,
    });
    return PresencaToken.fromRpc(Map<String, dynamic>.from(data as Map));
  }

  Future<CheckinResult> registrarCheckin(String token) async {
    final data = await supabase.rpc('registrar_presenca_checkin', params: {
      'p_token': token,
    });
    return CheckinResult.fromRpc(Map<String, dynamic>.from(data as Map));
  }
}
