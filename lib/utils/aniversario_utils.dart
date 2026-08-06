import '../models/aluno.dart';
import '../repositories/aluno_repository.dart';
import 'date_utils.dart';

Future<List<Aluno>> carregarAniversariantesTurma(AlunoRepository repo, String alunoId) async {
  final colegas = await repo.listarColegasDeTurmas(alunoId);
  return aniversariantesHoje(colegas: colegas, excluirAlunoId: alunoId);
}

bool aniversarioHoje(String? dataNascimento) {
  final nasc = parseDataNascimento(dataNascimento);
  if (nasc == null) return false;
  final hoje = DateTime.now();
  return nasc.month == hoje.month && nasc.day == hoje.day;
}

bool aniversarioNoMes(String? dataNascimento, {int? mes}) {
  final nasc = parseDataNascimento(dataNascimento);
  if (nasc == null) return false;
  final m = mes ?? DateTime.now().month;
  return nasc.month == m;
}

int? diaAniversario(String? dataNascimento) {
  final nasc = parseDataNascimento(dataNascimento);
  return nasc?.day;
}

/// Colegas de turma que fazem aniversário hoje (exclui o próprio aluno).
List<Aluno> aniversariantesHoje({
  required List<Aluno> colegas,
  String? excluirAlunoId,
}) {
  return colegas
      .where((a) =>
          a.ativo &&
          a.cadastroValidado &&
          a.id != excluirAlunoId &&
          aniversarioHoje(a.dataNascimento))
      .toList()
    ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
}

/// Quadro automático: aniversariantes do mês (ativos e validados), por dia e nome.
List<Aluno> aniversariantesDoMes({
  required List<Aluno> alunos,
  int? mes,
}) {
  final m = mes ?? DateTime.now().month;
  final lista = alunos
      .where((a) => a.ativo && a.cadastroValidado && aniversarioNoMes(a.dataNascimento, mes: m))
      .toList();
  lista.sort((a, b) {
    final da = diaAniversario(a.dataNascimento) ?? 99;
    final db = diaAniversario(b.dataNascimento) ?? 99;
    if (da != db) return da.compareTo(db);
    return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
  });
  return lista;
}
