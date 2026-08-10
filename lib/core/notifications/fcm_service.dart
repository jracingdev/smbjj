import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_platform.dart';
import '../supabase_service.dart';
import 'admin_notification_nav.dart';
import 'local_notification_service.dart';

/// Handler em isolate separado (app em background).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('FCM background Firebase.init: $e');
  }
  // Com payload `notification`, o sistema Android já exibe a notificação.
  // Aqui só logamos / reservamos para data-only futuros.
  debugPrint('FCM background: ${message.messageId} ${message.data}');
}

/// Push FCM para admins (complementa polling + local notifications).
///
/// Degrada gracefully se Firebase / google-services.json não estiver configurado.
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  bool _pronto = false;
  bool get disponivel => _pronto;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  Future<void> inicializar() async {
    if (_pronto || kIsWeb || !isNativeApp) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Garante canal Android (mesmo do LocalNotificationService) antes de pushes.
      await LocalNotificationService.instance.inicializar();

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen(_onForeground);

      _openedSub?.cancel();
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _aplicarNavegacao(initial);
      }

      _tokenSub?.cancel();
      _tokenSub = messaging.onTokenRefresh.listen((token) {
        unawaited(salvarTokenSeAdmin(token));
      });

      _pronto = true;
      debugPrint('FcmService: Firebase Messaging pronto');
    } catch (e, st) {
      _pronto = false;
      debugPrint(
        'FcmService: Firebase indisponível (coloque google-services.json). $e\n$st',
      );
    }
  }

  Future<void> sincronizarComUsuario({required bool isAdmin}) async {
    if (!_pronto) return;
    if (!isAdmin) {
      await limparTokenLocal();
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await salvarTokenSeAdmin(token);
      }
    } catch (e) {
      debugPrint('FcmService.sincronizarComUsuario: $e');
    }
  }

  Future<void> salvarTokenSeAdmin(String token) async {
    if (kIsWeb || !isNativeApp) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final perfil = await supabase
          .from('usuarios')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (perfil == null || perfil['role'] != 'admin') return;

      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      await supabase.from('admin_fcm_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );
      debugPrint('FcmService: token admin salvo');
    } catch (e) {
      debugPrint('FcmService.salvarTokenSeAdmin: $e');
    }
  }

  /// Remove o token atual do Supabase (logout) e tenta deleteToken local.
  Future<void> limparTokenNoLogout() async {
    if (kIsWeb || !isNativeApp) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? token;
      if (_pronto) {
        try {
          token = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
      }

      if (user != null) {
        var q = supabase.from('admin_fcm_tokens').delete().eq('user_id', user.id);
        if (token != null && token.isNotEmpty) {
          q = q.eq('token', token);
        }
        await q;
      }
    } catch (e) {
      debugPrint('FcmService.limparTokenNoLogout: $e');
    }

    await limparTokenLocal();
  }

  Future<void> limparTokenLocal() async {
    if (!_pronto) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('FcmService.limparTokenLocal: $e');
    }
  }

  void _onForeground(RemoteMessage message) {
    final titulo = message.notification?.title ??
        message.data['titulo']?.toString() ??
        'CT SM BJJ';
    final corpo = message.notification?.body ??
        message.data['mensagem']?.toString() ??
        message.data['body']?.toString() ??
        '';
    if (corpo.isEmpty && (message.notification == null)) return;

    final tipo = message.data['tipo']?.toString();
    unawaited(
      LocalNotificationService.instance.mostrar(
        titulo: titulo,
        mensagem: corpo.isEmpty ? titulo : corpo,
        payload: tipo,
        id: message.messageId?.hashCode,
      ),
    );
  }

  void _onOpened(RemoteMessage message) {
    _aplicarNavegacao(message);
  }

  void _aplicarNavegacao(RemoteMessage message) {
    final destino = AdminNotificationNav.fromPayload(
      message.data['tipo']?.toString(),
    );
    if (destino != null) {
      AdminNotificationNav.abrir(destino);
    }
  }

  void dispose() {
    _tokenSub?.cancel();
    _foregroundSub?.cancel();
    _openedSub?.cancel();
  }
}
