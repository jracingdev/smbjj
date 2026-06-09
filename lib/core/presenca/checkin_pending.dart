/// Token de check-in aguardando login ou processamento.
class CheckinPending {
  CheckinPending._();

  static String? token;

  static void definir(String? value) => token = value;

  static String? consumir() {
    final t = token;
    token = null;
    return t;
  }
}
