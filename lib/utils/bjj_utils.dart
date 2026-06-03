import 'package:flutter/material.dart';

const List<String> faixas = [
  'branca', 'cinza', 'amarela', 'laranja', 'verde',
  'azul', 'roxa', 'marrom', 'preta',
];

const List<String> meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

const double valorMenor = 80.0;
const double valorCheio = 110.0;

int? calcularIdadeCBJJ(String? dataNascimento) {
  if (dataNascimento == null || dataNascimento.isEmpty) return null;
  try {
    final nasc = DateTime.parse(dataNascimento);
    return DateTime.now().year - nasc.year;
  } catch (_) {
    return null;
  }
}

String getCategoriaEtaria(String? dataNascimento) {
  final idade = calcularIdadeCBJJ(dataNascimento);
  if (idade == null) return '—';
  if (idade < 4) return 'Bebê';
  if (idade <= 5) return 'Baby (4-5)';
  if (idade <= 7) return 'Mini Infantil (6-7)';
  if (idade <= 9) return 'Infantil (8-9)';
  if (idade <= 11) return 'Infanto Juvenil (10-11)';
  if (idade <= 13) return 'Juvenil (12-13)';
  if (idade <= 15) return 'Juvenil (14-15)';
  if (idade <= 17) return 'Juvenil (16-17)';
  if (idade <= 29) return 'Adulto';
  if (idade <= 35) return 'Master 1 (30-35)';
  if (idade <= 40) return 'Master 2 (36-40)';
  if (idade <= 45) return 'Master 3 (41-45)';
  if (idade <= 50) return 'Master 4 (46-50)';
  if (idade <= 55) return 'Master 5 (51-55)';
  if (idade <= 60) return 'Master 6 (56-60)';
  return 'Master 7 (61+)';
}

double getValorMensalidade(String? dataNascimento) {
  final idade = calcularIdadeCBJJ(dataNascimento);
  return (idade != null && idade < 18) ? valorMenor : valorCheio;
}

Color getFaixaColor(String faixa) {
  switch (faixa) {
    case 'branca': return Colors.white;
    case 'cinza': return Colors.grey;
    case 'amarela': return Colors.amber;
    case 'laranja': return Colors.orange;
    case 'verde': return Colors.green;
    case 'azul': return Colors.blue;
    case 'roxa': return Colors.purple;
    case 'marrom': return const Color(0xFF795548);
    case 'preta': return Colors.black;
    default: return Colors.white;
  }
}

Color getFaixaTextColor(String faixa) {
  switch (faixa) {
    case 'branca':
    case 'amarela':
      return Colors.black87;
    default:
      return Colors.white;
  }
}
