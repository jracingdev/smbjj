import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/app_platform.dart';
import 'alert_preferences_service.dart';

/// Notificações do sistema (Android) com canal sonoro + ícone do app.
///
/// Sem FCM: funciona com app em foreground/background enquanto o processo
/// estiver vivo (polling). App morto/kill não recebe push remoto.
class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  static const _channelId = 'smbjj_admin_alerts';
  static const _channelName = 'Alertas do admin';
  static const _channelDesc = 'Novos cadastros e pedidos da loja';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;
  int _seq = 1000;

  Future<void> inicializar() async {
    if (_pronto || kIsWeb || !isNativeApp) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_smbjj');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(settings: initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android?.requestNotificationsPermission();

    _pronto = true;
  }

  Future<void> mostrar({
    required String titulo,
    required String mensagem,
    int? id,
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
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
