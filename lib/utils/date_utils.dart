import 'package:flutter/services.dart';

/// Aceita DD-MM-AAAA, DD/MM/AAAA ou ISO (AAAA-MM-DD) do banco.
DateTime? parseDataNascimento(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final s = value.trim();

  final br = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$');
  final mBr = br.firstMatch(s);
  if (mBr != null) {
    final dia = int.parse(mBr.group(1)!);
    final mes = int.parse(mBr.group(2)!);
    final ano = int.parse(mBr.group(3)!);
    if (mes < 1 || mes > 12 || dia < 1 || dia > 31) return null;
    try {
      return DateTime(ano, mes, dia);
    } catch (_) {
      return null;
    }
  }

  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
  final mIso = iso.firstMatch(s);
  if (mIso != null) {
    try {
      return DateTime(
        int.parse(mIso.group(1)!),
        int.parse(mIso.group(2)!),
        int.parse(mIso.group(3)!),
      );
    } catch (_) {
      return null;
    }
  }

  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

/// Exibe no formulário: DD-MM-AAAA.
String formatDataNascimentoBr(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final dt = parseDataNascimento(value);
  if (dt == null) return value.trim();
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$d-$m-${dt.year}';
}

/// Salva no Supabase como AAAA-MM-DD.
String? dataNascimentoParaIso(String? input) {
  final dt = parseDataNascimento(input);
  if (dt == null) return null;
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

const String hintDataNascimento = 'DD-MM-AAAA';

/// Máscara enquanto digita: 99-99-9999
class DataNascimentoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) {
      return oldValue;
    }

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buf.write('-');
      buf.write(digits[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
