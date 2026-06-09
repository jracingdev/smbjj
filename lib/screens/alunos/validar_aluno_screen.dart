import 'package:flutter/material.dart';
import '../../core/financeiro/mensalidade_gerador_service.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../models/financeiro_config.dart';
import '../../models/turma.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/financeiro_config_repository.dart';
import '../../repositories/turma_repository.dart';
import '../../utils/bjj_utils.dart';
import '../../utils/date_utils.dart';
import '../../utils/turma_utils.dart';
import '../../widgets/faixa_badge.dart';
import '../../widgets/mes_ano_picker.dart';

class ValidarAlunoScreen extends StatefulWidget {
  final Aluno aluno;
  const ValidarAlunoScreen({super.key, required this.aluno});

  @override
  State<ValidarAlunoScreen> createState() => _ValidarAlunoScreenState();
}

class _ValidarAlunoScreenState extends State<ValidarAlunoScreen> {
  final _alunoRepo = AlunoRepository();
  final _turmaRepo = TurmaRepository();
  final _configRepo = FinanceiroConfigRepository();
  final _gerador = MensalidadeGeradorService();
  List<Turma> _turmas = [];
  final Set<String> _turmasSelecionadas = {};
  String _faixa = 'branca';
  int _grau = 0;
  bool _loading = true;
  bool _salvando = false;
  FinanceiroConfig _config = const FinanceiroConfig();

  bool _bolsista = false;
  final _pctBolsaCtrl = TextEditingController(text: '0');
  final _grupoCtrl = TextEditingController();
  final _cpfPaganteCtrl = TextEditingController();
  bool _proRataPrimeiroMes = true;
  bool _iniciante = false;
  String? _dataInicioAulas;

  @override
  void initState() {
    super.initState();
    _faixa = widget.aluno.faixa;
    _grau = widget.aluno.grau;
    _bolsista = widget.aluno.bolsista;
    _pctBolsaCtrl.text = widget.aluno.percentualBolsa.toStringAsFixed(0);
    _grupoCtrl.text = widget.aluno.grupoFamiliar ?? '';
    _cpfPaganteCtrl.text = widget.aluno.cpfPagante ?? '';
    _iniciante = widget.aluno.iniciante;
    _dataInicioAulas = widget.aluno.dataInicioAulas;
    _proRataPrimeiroMes = widget.aluno.proRataPrimeiroMes;
    _load();
  }

  @override
  void dispose() {
    _pctBolsaCtrl.dispose();
    _grupoCtrl.dispose();
    _cpfPaganteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _turmaRepo.listar(apenasAtivas: false),
      _turmaRepo.turmasDoAluno(widget.aluno.id),
      _configRepo.obter(),
    ]);
    _turmas = results[0] as List<Turma>;
    final atuais = results[1] as List<Turma>;
    _config = results[2] as FinanceiroConfig;
    _turmasSelecionadas.addAll(atuais.map((t) => t.id));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _validar() async {
    if (!widget.aluno.cadastroCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O aluno precisa completar todos os dados antes da validação.')),
      );
      return;
    }
    if (_turmasSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma turma.')),
      );
      return;
    }

    setState(() => _salvando = true);
    final primeiraValidacao = !widget.aluno.cadastroValidado;
    final hoje = DateTime.now().toIso8601String().split('T').first;

    try {
      final atualizado = widget.aluno.copyWith(
        faixa: _faixa,
        grau: _grau,
        bolsista: _bolsista,
        percentualBolsa: double.tryParse(_pctBolsaCtrl.text) ?? 0,
        grupoFamiliar: _grupoCtrl.text.trim().isEmpty ? null : _grupoCtrl.text.trim(),
        cpfPagante: _cpfPaganteCtrl.text.trim().isEmpty ? null : _cpfPaganteCtrl.text.trim(),
        dataInicioCobranca: widget.aluno.dataInicioCobranca ?? hoje,
        cobrancaAtiva: true,
        dataInicioAulas: _dataInicioAulas,
        iniciante: _iniciante,
        proRataPrimeiroMes: _iniciante ? _proRataPrimeiroMes : false,
      );
      await _alunoRepo.atualizar(atualizado);

      if (widget.aluno.cadastroValidado) {
        await _turmaRepo.substituirTurmasAluno(widget.aluno.id, _turmasSelecionadas.toList());
      } else {
        await _alunoRepo.validarComTurmas(widget.aluno.id, _turmasSelecionadas.toList());
        final cfg = await _configRepo.obter();
        final alunoDb = await _alunoRepo.buscarPorId(widget.aluno.id) ?? atualizado.copyWith(cadastroValidado: true, ativo: true);
        final n = await _gerador.gerarParaAlunoValidado(
          alunoDb,
          cfg,
          proRataPrimeiroMes: atualizado.proRataPrimeiroMes,
        );
        if (mounted && primeiraValidacao) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$n mensalidade(s) gerada(s) para o ano vigente.'), backgroundColor: verdeEscuro),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        if (!primeiraValidacao || widget.aluno.cadastroValidado) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.aluno.cadastroValidado
                    ? 'Turmas de ${widget.aluno.nome} atualizadas!'
                    : '${widget.aluno.nome} validado e incluído na turma!',
              ),
              backgroundColor: verdeEscuro,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.aluno;
    final categoria = getCategoriaEtaria(a.dataNascimento);
    final primeira = !a.cadastroValidado;

    return Scaffold(
      appBar: AppBar(title: Text(a.cadastroValidado ? 'Turmas do Aluno' : 'Validar Cadastro')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!a.cadastroCompleto)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Cadastro incompleto. Peça ao aluno para preencher telefone, cidade e demais dados.',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(a.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            ),
                            FaixaBadge(faixa: _faixa, grau: _grau),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('$categoria · ${a.email ?? "—"}'),
                        if (a.dataNascimento != null && a.dataNascimento!.isNotEmpty)
                          Text('Nascimento: ${formatDataNascimentoBr(a.dataNascimento)}'),
                        if (a.telefone != null) Text('Tel: ${a.telefone}'),
                        if (a.cidade != null) Text('${a.cidade}${a.estado != null ? " - ${a.estado}" : ""}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Graduação (definida pelo professor)', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _faixa,
                      decoration: const InputDecoration(labelText: 'Faixa'),
                      items: faixas
                          .map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1))))
                          .toList(),
                      onChanged: (v) => setState(() => _faixa = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _grau,
                      decoration: const InputDecoration(labelText: 'Grau'),
                      items: [0, 1, 2, 3, 4]
                          .map((g) => DropdownMenuItem(value: g, child: Text(g == 0 ? 'Sem grau' : '$g°')))
                          .toList(),
                      onChanged: (v) => setState(() => _grau = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                const Text('Início nas aulas', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                MesAnoPicker(
                  value: _dataInicioAulas,
                  onChanged: (v) => setState(() => _dataInicioAulas = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aluno iniciante'),
                  subtitle: const Text('Marque para aplicar pro-rata no primeiro mês'),
                  value: _iniciante,
                  onChanged: (v) => setState(() {
                    _iniciante = v;
                    if (!v) _proRataPrimeiroMes = false;
                  }),
                ),
                if (_iniciante && _config.proRataAtivo)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _proRataPrimeiroMes,
                    onChanged: (v) => setState(() => _proRataPrimeiroMes = v ?? false),
                    title: const Text('Pró-rata no primeiro mês', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Cobra proporcional aos dias restantes no mês de entrada'),
                  ),
                if (primeira) ...[
                  const SizedBox(height: 20),
                  const Text('Cobrança e descontos', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    'Ao validar, serão geradas as mensalidades do mês atual até dezembro.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bolsista'),
                    value: _bolsista,
                    onChanged: (v) => setState(() => _bolsista = v),
                  ),
                  if (_bolsista)
                    TextField(
                      controller: _pctBolsaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Percentual da bolsa (%)', suffixText: '%'),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _grupoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Grupo familiar (código)',
                      helperText: 'Mesmo código para irmãos — desconto progressivo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cpfPaganteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'CPF do pagante',
                      helperText: 'Desconto se o mesmo responsável paga mais de um aluno',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Turma(s) *', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Configure os dias de cada turma em "Gerenciar Turmas".',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                ..._turmas.map((t) {
                  final sel = _turmasSelecionadas.contains(t.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: sel,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _turmasSelecionadas.add(t.id);
                          } else {
                            _turmasSelecionadas.remove(t.id);
                          }
                        });
                      },
                      title: Text(t.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${formatarHorarioTurma(t.horario)} · ${formatarDiasSemana(t.diasSemana)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(Icons.groups, color: verdeEscuro.withValues(alpha: 0.8)),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _salvando || (primeira && !a.cadastroCompleto) ? null : _validar,
                  icon: const Icon(Icons.verified_user),
                  label: _salvando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(a.cadastroValidado ? 'Salvar turmas' : 'Validar e gerar mensalidades'),
                ),
              ],
            ),
    );
  }
}
