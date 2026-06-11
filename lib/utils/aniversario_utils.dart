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
      .toList();
}
