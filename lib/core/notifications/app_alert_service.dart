import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Alertas visuais e sonoros in-app (haptic + som do sistema + banner).
class AppAlertService {
  static Future<void> alertar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    Color? cor,
    Duration duracao = const Duration(seconds: 6),
  }) async {
    if (!context.mounted) return;
    await HapticFeedback.heavyImpact();
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }

    final bg = cor ?? Colors.orange.shade800;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: duracao,
        backgroundColor: bg,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_active, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(mensagem, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
