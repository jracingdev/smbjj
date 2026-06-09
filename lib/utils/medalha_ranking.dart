import '../models/medalha.dart';

int pontosMedalhaTipo(String tipo) {
  switch (tipo.trim().toLowerCase()) {
    case 'ouro':
      return 5;
    case 'prata':
      return 2;
    case 'bronze':
      return 1;
    default:
      return 0;
  }
}

String normalizarNomeAluno(String nome) =>
    nome.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Chave estável para agrupar todas as medalhas do mesmo aluno.
String chaveAlunoMedalhaDados({required String alunoId, required String alunoNome}) {
  final id = alunoId.trim().toLowerCase();
  if (id.isNotEmpty) return 'id:$id';
  return 'nome:${normalizarNomeAluno(alunoNome)}';
}

String chaveAlunoMedalha(Medalha m) =>
    chaveAlunoMedalhaDados(alunoId: m.alunoId, alunoNome: m.alunoNome);

class RankingMedalhasEntry {
  final String alunoId;
  final String alunoNome;
  final int ouro;
  final int prata;
  final int bronze;
  final int pontos;
  final int total;

  const RankingMedalhasEntry({
    required this.alunoId,
    required this.alunoNome,
    required this.ouro,
    required this.prata,
    required this.bronze,
    required this.pontos,
    required this.total,
  });
}

List<RankingMedalhasEntry> calcularRankingMedalhas(List<Medalha> medalhas) {
  final map = <String, ({String alunoId, String alunoNome, int ouro, int prata, int bronze, int pontos})>{};

  for (final m in medalhas.where((x) => x.ativo)) {
    final key = chaveAlunoMedalha(m);
    final prev = map[key];
    var ouro = prev?.ouro ?? 0;
    var prata = prev?.prata ?? 0;
    var bronze = prev?.bronze ?? 0;
    var pontos = prev?.pontos ?? 0;

    switch (m.tipo.trim().toLowerCase()) {
      case 'ouro':
        ouro++;
        break;
      case 'prata':
        prata++;
        break;
      case 'bronze':
        bronze++;
        break;
    }
    pontos += pontosMedalhaTipo(m.tipo);

    final nomeAtual = m.alunoNome.trim();
    final nomePrev = prev?.alunoNome ?? '';
    final alunoId = m.alunoId.trim().isNotEmpty ? m.alunoId : (prev?.alunoId ?? '');

    map[key] = (
      alunoId: alunoId,
      alunoNome: nomeAtual.length >= nomePrev.length ? nomeAtual : nomePrev,
      ouro: ouro,
      prata: prata,
      bronze: bronze,
      pontos: pontos,
    );
  }

  final lista = map.values
      .map(
        (r) => RankingMedalhasEntry(
          alunoId: r.alunoId,
          alunoNome: r.alunoNome,
          ouro: r.ouro,
          prata: r.prata,
          bronze: r.bronze,
          pontos: r.pontos,
          total: r.ouro + r.prata + r.bronze,
        ),
      )
      .toList()
    ..sort((a, b) {
      final cmp = b.pontos.compareTo(a.pontos);
      if (cmp != 0) return cmp;
      final cmpTotal = b.total.compareTo(a.total);
      if (cmpTotal != 0) return cmpTotal;
      return a.alunoNome.compareTo(b.alunoNome);
    });
  return lista;
}

Map<String, List<Medalha>> agruparMedalhasPorAluno(List<Medalha> medalhas) {
  final map = <String, List<Medalha>>{};
  for (final m in medalhas) {
    map.putIfAbsent(chaveAlunoMedalha(m), () => []).add(m);
  }
  for (final lista in map.values) {
    lista.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
  }
  return map;
}
