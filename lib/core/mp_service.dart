import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class MercadoPagoService {
  static final MercadoPagoService instance = MercadoPagoService._();
  MercadoPagoService._();

  static const _baseUrl = 'https://api.mercadopago.com';
  static const _prefKey = 'mp_access_token';
  static const _webhookUrl = '$supabaseUrl/functions/v1/mp-webhook';

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, token);
    // Persiste no Supabase para a Edge Function (webhook) usar
    try {
      await supabase.from('financeiro_config').update({'mp_access_token': token}).eq('id', 1);
    } catch (_) {}
  }

  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    try {
      await supabase.from('financeiro_config').update({'mp_access_token': null}).eq('id', 1);
    } catch (_) {}
  }

  Future<bool> validarToken(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Cria uma preferência de pagamento e retorna o link
  Future<MpPreferencia?> criarCobranca({
    required String titulo,
    required double valor,
    String? emailPagador,
    String? descricao,
    Map<String, String>? metadados,
  }) async {
    final token = await getAccessToken();
    if (token == null) return null;

    final body = {
      'items': [
        {
          'title': titulo,
          'quantity': 1,
          'unit_price': valor,
          'currency_id': 'BRL',
          if (descricao != null) 'description': descricao,
        }
      ],
      if (emailPagador != null) 'payer': {'email': emailPagador},
      'payment_methods': {
        'installments': 1,
      },
      'statement_descriptor': 'SM BJJ',
      if (metadados != null) 'metadata': metadados,
      'notification_url': _webhookUrl,
    };

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/checkout/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return MpPreferencia(
          id: data['id'],
          link: data['init_point'],
          linkSandbox: data['sandbox_init_point'],
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Consulta pagamentos de uma preferência e retorna o status do mais recente.
  /// Retorna 'approved', 'pending', 'rejected', etc. ou null se não encontrado.
  Future<String?> consultarStatus(String preferenciaId) async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse('$_baseUrl/v1/payments/search').replace(queryParameters: {
        'preference_id': preferenciaId,
        'sort': 'date_created',
        'criteria': 'desc',
        'limit': '5',
      });
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) return null;
        // Prioriza 'approved' — pode haver tentativas rejeitadas antes
        final aprovado = results.firstWhere(
          (r) => r['status'] == 'approved',
          orElse: () => results.first,
        );
        return aprovado['status'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class MpPreferencia {
  final String id;
  final String link;
  final String linkSandbox;

  MpPreferencia({required this.id, required this.link, required this.linkSandbox});
}
