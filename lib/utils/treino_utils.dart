import 'turma_utils.dart';

const _diaParaWeekday = {
  'segunda': DateTime.monday,
  'terca': DateTime.tuesday,
  'quarta': DateTime.wednesday,
  'quinta': DateTime.thursday,
  'sexta': DateTime.friday,
  'sabado': DateTime.saturday,
  'domingo': DateTime.sunday,
};

/// Próximas datas de treino com base nos dias da semana da turma.
List<DateTime> proximosTreinos(List<String> diasSemana, {int quantidade = 6, DateTime? aPartirDe}) {
  if (diasSemana.isEmpty) return [];
  final weekdays = diasSemana.map((d) => _diaParaWeekday[d]).whereType<int>().toSet();
  if (weekdays.isEmpty) return [];

  final inicio = aPartirDe ?? DateTime.now();
  final hoje = DateTime(inicio.year, inicio.month, inicio.day);
  final datas = <DateTime>[];

  for (var i = 0; i < 60 && datas.length < quantidade; i++) {
    final d = hoje.add(Duration(days: i));
    if (weekdays.contains(d.weekday)) {
      datas.add(d);
    }
  }
  return datas;
}

String resumoProximoTreino(List<String> diasSemana, String horario) {
  final prox = proximosTreinos(diasSemana, quantidade: 1);
  if (prox.isEmpty) {
    return '${formatarHorarioTurma(horario)} · ${formatarDiasSemana(diasSemana)}';
  }
  final d = prox.first;
  final diaLabel = diasSemanaOpcoes.firstWhere(
    (x) => _diaParaWeekday[x['id']] == d.weekday,
    orElse: () => {'label': ''},
  )['label'];
  return 'Próximo: $diaLabel · ${formatarHorarioTurma(horario)}';
}
