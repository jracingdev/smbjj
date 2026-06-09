import 'package:flutter/services.dart';

/// Formatos de exibição no app:
/// - Data completa: DD-MM-YYYY
/// - Mês/ano: MM-YYYY
/// O banco continua usando ISO (YYYY-MM-DD ou YYYY-MM).

const String hintDataCompleta = 'DD-MM-YYYY';
const String hintMesAno = 'MM-YYYY';

/// Aceita DD-MM-YYYY, DD/MM/YYYY ou ISO (YYYY-MM-DD) do banco.
DateTime? parseDataCompleta(String? value) {
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

DateTime? parseDataNascimento(String? value) => parseDataCompleta(value);

/// Exibe data completa: DD-MM-YYYY.
String formatDataBr(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final dt = parseDataCompleta(value);
  if (dt == null) return value.trim();
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$d-$m-${dt.year}';
}

/// Alias — nascimento e demais datas completas usam o mesmo formato.
String formatDataNascimentoBr(String? value) => formatDataBr(value);

/// Salva no Supabase como YYYY-MM-DD.
String? dataCompletaParaIso(String? input) {
  final dt = parseDataCompleta(input);
  if (dt == null) return null;
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String? dataNascimentoParaIso(String? input) => dataCompletaParaIso(input);

const String hintDataNascimento = hintDataCompleta;

/// Parse mês/ano: YYYY-MM (banco), MM-YYYY ou MM/YYYY (entrada).
(int mes, int ano)? parseMesAno(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final s = value.trim();

  final iso = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(s);
  if (iso != null) {
    final ano = int.tryParse(iso.group(1)!);
    final mes = int.tryParse(iso.group(2)!);
    if (ano == null || mes == null || mes < 1 || mes > 12) return null;
    return (mes, ano);
  }

  final br = RegExp(r'^(\d{1,2})[/-](\d{4})$').firstMatch(s);
  if (br != null) {
    final mes = int.tryParse(br.group(1)!);
    final ano = int.tryParse(br.group(2)!);
    if (ano == null || mes == null || mes < 1 || mes > 12) return null;
    return (mes, ano);
  }

  return null;
}

/// Grava no banco como YYYY-MM.
String mesAnoParaIso(int mes, int ano) =>
    '${ano.toString().padLeft(4, '0')}-${mes.toString().padLeft(2, '0')}';

/// Exibe mês/ano: MM-YYYY.
String formatMesAnoBr(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final p = parseMesAno(value);
  if (p == null) return value.trim();
  return formatMesAnoPartes(p.$1, p.$2);
}

/// MM-YYYY a partir de mês e ano numéricos.
String formatMesAnoPartes(int mes, int ano) =>
    '${mes.toString().padLeft(2, '0')}-$ano';

/// Label: "Aluno desde: MM-YYYY"
String labelAlunoDesde(String? dataInicioAulas) {
  final fmt = formatMesAnoBr(dataInicioAulas);
  if (fmt.isEmpty) return '';
  return 'Aluno desde: $fmt';
}

/// Máscara enquanto digita data completa: DD-MM-YYYY
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
