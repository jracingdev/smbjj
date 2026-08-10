import 'package:flutter/foundation.dart';

/// Destino de navegação ao tocar numa push/local do admin.
enum AdminNotifDestino { alunos, loja }

/// Ponte simples entre handlers FCM e [MainScreen].
class AdminNotificationNav {
  AdminNotificationNav._();

  static final ValueNotifier<AdminNotifDestino?> pending =
      ValueNotifier<AdminNotifDestino?>(null);

  static void abrir(AdminNotifDestino destino) {
    pending.value = destino;
  }

  static void limpar() {
    pending.value = null;
  }

  static AdminNotifDestino? fromPayload(String? tipo) {
    switch ((tipo ?? '').toLowerCase()) {
      case 'aluno':
      case 'alunos':
      case 'cadastro':
        return AdminNotifDestino.alunos;
      case 'pedido':
      case 'pedidos':
      case 'loja':
        return AdminNotifDestino.loja;
      default:
        return null;
    }
  }
}
