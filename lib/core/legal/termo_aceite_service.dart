import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registra aceite de termos (nome, data/hora, IP) no Supabase.
class TermoAceiteService {
  TermoAceiteService._();
  static final instance = TermoAceiteService._();

  static const _tipos = (
    termosUso: 'termos_uso',
    aptidaoFisica: 'aptidao_fisica',
    privacidade: 'privacidade',
  );

  Future<void> registrarAceitesCadastro({
    required String nome,
    required String email,
    String? userId,
    required bool termosUso,
    required bool aptidaoFisica,
  }) async {
    final ip = await _obterIpPublico();
    final agent = kIsWeb ? 'web' : defaultTargetPlatform.name;

    if (termosUso) {
      await _inserir(
        tipo: _tipos.termosUso,
        nome: nome,
        email: email,
        userId: userId,
        ip: ip,
        userAgent: agent,
      );
      await _inserir(
        tipo: _tipos.privacidade,
        nome: nome,
        email: email,
        userId: userId,
        ip: ip,
        userAgent: agent,
      );
    }
    if (aptidaoFisica) {
      await _inserir(
        tipo: _tipos.aptidaoFisica,
        nome: nome,
        email: email,
        userId: userId,
        ip: ip,
        userAgent: agent,
      );
    }
  }

  Future<void> _inserir({
    required String tipo,
    required String nome,
    required String? email,
    required String? userId,
    required String? ip,
    required String userAgent,
  }) async {
    try {
      await Supabase.instance.client.from('termos_aceites').insert({
        'user_id': userId,
        'nome': nome,
        'email': email,
        'tipo': tipo,
        'ip': ip,
        'user_agent': userAgent,
      });
    } catch (e) {
      debugPrint('TermoAceiteService: falha ao registrar $tipo — $e');
    }
  }

  Future<String?> _obterIpPublico() async {
    try {
      final r = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        return j['ip'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
