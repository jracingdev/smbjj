import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_platform.dart';
import 'fcm_service.dart';
import 'local_notification_service.dart';

/// Status da permissão de notificações do sistema (Android 13+ / iOS).
enum NotifPermStatus {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

/// Pedido de permissão no momento certo + abertura das configurações do app.
class NotificationPermissionService {
  NotificationPermissionService._();
  static final instance = NotificationPermissionService._();

  static const _prefsPromptedKey = 'admin_notif_prompt_v1';

  Future<NotifPermStatus> status() async {
    if (kIsWeb || !isNativeApp) return NotifPermStatus.unavailable;

    try {
      await LocalNotificationService.instance.inicializar(pedirPermissao: false);
      final enabled =
          await LocalNotificationService.instance.androidPlugin?.areNotificationsEnabled();
      if (enabled == true) return NotifPermStatus.granted;

      final ph = await Permission.notification.status;
      if (ph.isGranted) return NotifPermStatus.granted;
      if (ph.isPermanentlyDenied) return NotifPermStatus.permanentlyDenied;
      return NotifPermStatus.denied;
    } catch (_) {
      final ph = await Permission.notification.status;
      if (ph.isGranted) return NotifPermStatus.granted;
      if (ph.isPermanentlyDenied) return NotifPermStatus.permanentlyDenied;
      return NotifPermStatus.denied;
    }
  }

  Future<bool> get isGranted async =>
      (await status()) == NotifPermStatus.granted;

  /// Abre as configurações do app para o usuário ligar notificações.
  Future<bool> abrirConfiguracoes() => openAppSettings();

  /// Pede permissão do sistema. Se já negada permanentemente, abre settings.
  Future<NotifPermStatus> solicitar({bool abrirSettingsSeNegado = true}) async {
    if (kIsWeb || !isNativeApp) return NotifPermStatus.unavailable;

    await LocalNotificationService.instance.inicializar(pedirPermissao: false);

    var atual = await status();
    if (atual == NotifPermStatus.granted) {
      await FcmService.instance.garantirPermissaoMessaging();
      return atual;
    }

    if (atual == NotifPermStatus.permanentlyDenied) {
      if (abrirSettingsSeNegado) await abrirConfiguracoes();
      return await status();
    }

    final okLocal = await LocalNotificationService.instance.androidPlugin
        ?.requestNotificationsPermission();
    if (okLocal == true) {
      await FcmService.instance.garantirPermissaoMessaging();
      return NotifPermStatus.granted;
    }

    final ph = await Permission.notification.request();
    if (ph.isGranted) {
      await FcmService.instance.garantirPermissaoMessaging();
      return NotifPermStatus.granted;
    }

    atual = await status();
    if (atual != NotifPermStatus.granted &&
        (ph.isPermanentlyDenied || atual == NotifPermStatus.permanentlyDenied) &&
        abrirSettingsSeNegado) {
      await abrirConfiguracoes();
      return await status();
    }
    return atual;
  }

  /// Diálogo explicativo pós-login admin + pedido de permissão.
  Future<void> garantirAposLoginAdmin(BuildContext context) async {
    if (!isNativeApp || !context.mounted) return;

    final st = await status();
    if (st == NotifPermStatus.granted) {
      await FcmService.instance.garantirPermissaoMessaging();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jaPediu = prefs.getBool(_prefsPromptedKey) ?? false;

    if (!FcmService.instance.disponivel && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Push indisponível'),
          content: const Text(
            'As notificações remotas (com o app fechado) não iniciaram neste aparelho. '
            'Alertas com o app aberto ainda podem funcionar. '
            'Confira se o app está atualizado ou reinstale.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendi')),
          ],
        ),
      );
    }

    if (!context.mounted) return;

    // Já pediu e o usuário só adiou (ainda dá para pedir de novo via Perfil).
    if (jaPediu && st == NotifPermStatus.denied) return;

    final permanente = st == NotifPermStatus.permanentlyDenied;
    final ir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(permanente ? 'Notificações desativadas' : 'Ativar notificações'),
        content: Text(
          permanente
              ? 'A permissão foi negada neste aparelho. Abra as configurações do app e ligue Notificações para receber alertas de novos alunos e pedidos da loja.'
              : 'Para avisar sobre novos alunos e pedidos da loja — mesmo com o app fechado — '
                  'o CT SM BJJ precisa da permissão de notificações do Android.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(permanente ? 'Abrir configurações' : 'Ativar'),
          ),
        ],
      ),
    );

    await prefs.setBool(_prefsPromptedKey, true);
    if (ir != true || !context.mounted) return;

    final result = await solicitar(abrirSettingsSeNegado: true);
    if (!context.mounted) return;

    if (result != NotifPermStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Notificações ainda desativadas. Em Configurações do app, ligue Notificações.',
          ),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () => abrirConfiguracoes(),
          ),
        ),
      );
    }
  }
}
