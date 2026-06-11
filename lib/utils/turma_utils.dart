const List<Map<String, String>> diasSemanaOpcoes = [
  {'id': 'segunda', 'label': 'Segunda'},
  {'id': 'terca', 'label': 'Terça'},
  {'id': 'quarta', 'label': 'Quarta'},
  {'id': 'quinta', 'label': 'Quinta'},
  {'id': 'sexta', 'label': 'Sexta'},
  {'id': 'sabado', 'label': 'Sábado'},
  {'id': 'domingo', 'label': 'Domingo'},
];

String labelDiaSemana(String id) {
  return diasSemanaOpcoes.firstWhere(
    (d) => d['id'] == id,
    orElse: () => {'label': id},
  )['label']!;
}

String formatarDiasSemana(List<String> dias) {
  if (dias.isEmpty) return 'Dias a definir';
  return dias.map(labelDiaSemana).join(', ');
}

String formatarHorarioTurma(String horario) {
  if (horario.length == 5 && horario.contains(':')) return '${horario}h';
  return horario;
}

/// Ex.: "Turma Mista Noite" → "Mista Noite"
String nomeTurmaCurto(String nome) =>
    nome.replaceFirst(RegExp(r'^turma\s+', caseSensitive: false), '').trim();
