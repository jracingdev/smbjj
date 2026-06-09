import '../models/aluno.dart';
import 'date_utils.dart';

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
