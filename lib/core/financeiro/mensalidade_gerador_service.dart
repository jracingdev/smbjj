import 'package:uuid/uuid.dart';

import '../../models/aluno.dart';
import '../../models/financeiro_config.dart';
import '../../models/mensalidade.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/mensalidade_repository.dart';
import 'calculo_mensalidade.dart';

/// Gera mensalidades do mês de início até dezembro do ano vigente e trata interrupções.
class MensalidadeGeradorService {
  final _mensRepo = MensalidadeRepository();
  final _alunoRepo = AlunoRepository();
  final _uuid = const Uuid();

  Future<int> gerarParaAlunoValidado(
    Aluno aluno,
    FinanceiroConfig config, {
    DateTime? dataInicio,
    bool proRataPrimeiroMes = true,
  }) async {
    final inicio = dataInicio ?? DateTime.now();
    final dataIso = inicio.toIso8601String().split('T').first;

    final atualizado = aluno.copyWith(
      cadastroValidado: true,
      ativo: true,
      cobrancaAtiva: true,
      dataInicioCobranca: aluno.dataInicioCobranca ?? dataIso,
    );
    await _alunoRepo.atualizar(atualizado);

    return gerarAnoVigente(atualizado, config, proRataPrimeiroMes: proRataPrimeiroMes);
  }

  Future<int> gerarAnoVigente(
    Aluno aluno,
    FinanceiroConfig config, {
    bool proRataPrimeiroMes = false,
  }) async {
    if (!aluno.cobrancaAtiva) return 0;

    final todos = await _alunoRepo.listar(ativo: true);
    final existentes = await _mensRepo.porAluno(aluno.id);
    final inicioStr = aluno.dataInicioCobranca;
    final inicio = inicioStr != null && inicioStr.isNotEmpty
        ? DateTime.tryParse(inicioStr) ?? DateTime.now()
        : DateTime.now();
    final ano = inicio.year;
    var criadas = 0;

    for (var mes = inicio.month; mes <= 12; mes++) {
      if (_jaExiste(existentes, mes, ano)) continue;
      if (_aposInterrupcao(aluno, mes, ano)) continue;

      final base = calcularValorMensalidadeAluno(aluno, config, todos);
      if (base <= 0) continue;

      var valor = base;
      var proRata = false;
      final deveAplicarProRata = proRataPrimeiroMes && aluno.proRataPrimeiroMes && aluno.iniciante && config.proRataAtivo;
      if (mes == inicio.month && ano == inicio.year && deveAplicarProRata) {
        valor = aplicarProRata(base, inicio);
        proRata = valor < base;
      }

      await _mensRepo.criar(Mensalidade(
        id: _uuid.v4(),
        alunoId: aluno.id,
        alunoNome: aluno.nome,
        mes: mes,
        ano: ano,
        valor: valor,
        valorBase: base,
        proRata: proRata,
        observacao: proRata ? 'Pro-rata (${inicio.day}/${DateTime(inicio.year, inicio.month + 1, 0).day})' : null,
      ));
      criadas++;
    }
    return criadas;
  }

  Future<void> interromperCobranca({
    required Aluno aluno,
    required String justificativa,
    DateTime? dataFim,
    bool aplicarProRataMesAtual = false,
    FinanceiroConfig? config,
  }) async {
    final fim = dataFim ?? DateTime.now();
    final fimIso = fim.toIso8601String().split('T').first;
    final cfg = config ?? const FinanceiroConfig();

    if (aplicarProRataMesAtual) {
      final todos = await _alunoRepo.listar(ativo: true);
      final base = calcularValorMensalidadeAluno(aluno, cfg, todos);
      final valorPr = aplicarProRata(base, fim);
      final lista = await _mensRepo.porAluno(aluno.id);
      final atual = lista.where((m) =>
          m.mes == fim.month && m.ano == fim.year && !m.cancelada && m.status != 'pago');
      if (atual.isNotEmpty) {
        final m = atual.first;
        await _mensRepo.atualizar(m.copyWith(
          valor: valorPr,
          proRata: true,
          valorBase: base,
          observacao: 'Interrupção pro-rata: $justificativa',
        ));
      }
    }

    await _mensRepo.cancelarFuturas(
      alunoId: aluno.id,
      aPartirMes: fim.month == 12 ? 1 : fim.month + 1,
      aPartirAno: fim.month == 12 ? fim.year + 1 : fim.year,
      justificativa: justificativa,
    );

    await _alunoRepo.atualizar(aluno.copyWith(
      cobrancaAtiva: false,
      ativo: false,
      dataInterrupcaoCobranca: fimIso,
      justificativaInterrupcao: justificativa,
    ));
  }

  bool _jaExiste(List<Mensalidade> lista, int mes, int ano) =>
      lista.any((m) => m.mes == mes && m.ano == ano && !m.cancelada);

  bool _aposInterrupcao(Aluno aluno, int mes, int ano) {
    final fim = aluno.dataInterrupcaoCobranca;
    if (fim == null || fim.isEmpty) return false;
    final d = DateTime.tryParse(fim);
    if (d == null) return false;
    if (ano > d.year) return true;
    if (ano == d.year && mes > d.month) return true;
    return false;
  }
}
