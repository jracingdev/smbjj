import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/app_platform.dart';
import 'admin_notification_nav.dart';
import 'alert_preferences_service.dart';

/// Notificações do sistema (Android) com canal sonoro + ícone do app.
///
/// Polling local: foreground/background com processo vivo.
/// FCM: usa o mesmo canal/ícone para app morto (via push remoto).
class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  static const channelId = 'smbjj_admin_alerts';
  static const channelName = 'Alertas do admin';
  static const channelDesc = 'Novos cadastros e pedidos da loja';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;
  int _seq = 1000;

  Future<void> inicializar() async {
    if (_pronto || kIsWeb || !isNativeApp) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_smbjj');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android?.requestNotificationsPermission();

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch!.notificationResponse?.payload;
      final destino = AdminNotificationNav.fromPayload(payload);
      if (destino != null) AdminNotificationNav.abrir(destino);
    }

    _pronto = true;
  }

  void _onTap(NotificationResponse response) {
    final destino = AdminNotificationNav.fromPayload(response.payload);
    if (destino != null) AdminNotificationNav.abrir(destino);
  }

  Future<void> mostrar({
    required String titulo,
    required String mensagem,
    int? id,
    String? payload,
  }) async {
    if (kIsWeb || !isNativeApp) return;

    final prefs = AlertPreferencesService.instance;
    final som = await prefs.alertasSomAtivos;
    final visual = await prefs.alertasVisuaisAtivos;
    if (!som && !visual) return;

    if (!_pronto) await inicializar();

    final notifId = id ?? (++_seq);
    await _plugin.show(
      id: notifId,
      title: titulo,
      body: mensagem,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: som,
          enableVibration: som,
          icon: '@drawable/ic_stat_smbjj',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(mensagem),
          category: AndroidNotificationCategory.message,
        ),
      ),
    );
  }
}
