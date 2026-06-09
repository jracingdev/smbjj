import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/supabase_errors.dart';
import '../../core/theme.dart';
import '../../repositories/presenca_checkin_repository.dart';
import '../../utils/date_utils.dart';
import 'checkin_pending.dart';
import 'checkin_url.dart';

/// Processa ?checkin=TOKEN na URL ou token pendente após login.
class CheckinHandler {
  static Future<void> processarUrlInicial() async {
    final uri = Uri.base;
    final t = uri.queryParameters['checkin'];
    if (t != null && t.isNotEmpty) CheckinPending.definir(t);
  }

  static Future<void> tentarProcessarPendente(BuildContext context) async {
    final token = CheckinPending.consumir();
    if (token == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    if (!auth.autenticado || auth.isAdmin) return;
    if (auth.carregando || auth.carregandoAluno) return;

    await _executarCheckin(context, token);
  }

  static Future<void> executarComToken(BuildContext context, String raw) async {
    final token = tokenDeUrlOuQr(raw);
    if (token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR inválido. Escaneie o código da academia.')),
        );
      }
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.autenticado) {
      CheckinPending.definir(token);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login para registrar sua presença.')),
        );
      }
      return;
    }
    if (auth.isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in é para alunos. Use a tela de presença do admin.')),
        );
      }
      return;
    }

    await _executarCheckin(context, token);
  }

  static Future<void> _executarCheckin(BuildContext context, String token) async {
    try {
      final result = await PresencaCheckinRepository().registrarCheckin(token);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: verdeEscuro, size: 48),
          title: const Text('Presença registrada!'),
          content: Text(
            '${result.alunoNome}\n'
            'Turma: ${result.turmaNome}\n'
            'Data: ${formatDataBr(result.dataAula)}',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemErroSupabase(e, recurso: 'a presença')),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
