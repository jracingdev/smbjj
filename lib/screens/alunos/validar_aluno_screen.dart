import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../models/turma.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/turma_repository.dart';
import '../../utils/bjj_utils.dart';
import '../../utils/date_utils.dart';
import '../../utils/turma_utils.dart';
import '../../widgets/faixa_badge.dart';

class ValidarAlunoScreen extends StatefulWidget {
  final Aluno aluno;
  const ValidarAlunoScreen({super.key, required this.aluno});

  @override
  State<ValidarAlunoScreen> createState() => _ValidarAlunoScreenState();
}

class _ValidarAlunoScreenState extends State<ValidarAlunoScreen> {
  final _alunoRepo = AlunoRepository();
  final _turmaRepo = TurmaRepository();
  List<Turma> _turmas = [];
  final Set<String> _turmasSelecionadas = {};
  String _faixa = 'branca';
  int _grau = 0;
  bool _loading = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _faixa = widget.aluno.faixa;
    _grau = widget.aluno.grau;
    _load();
  }

  Future<void> _load() async {
    _turmas = await _turmaRepo.listar();
    final atuais = await _turmaRepo.turmasDoAluno(widget.aluno.id);
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
    final atualizado = widget.aluno.copyWith(faixa: _faixa, grau: _grau);
    await _alunoRepo.atualizar(atualizado);
    if (widget.aluno.cadastroValidado) {
      await _turmaRepo.substituirTurmasAluno(widget.aluno.id, _turmasSelecionadas.toList());
    } else {
      await _alunoRepo.validarComTurmas(widget.aluno.id, _turmasSelecionadas.toList());
    }

    if (mounted) {
      Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final a = widget.aluno;
    final categoria = getCategoriaEtaria(a.dataNascimento);

    return Scaffold(
      appBar: AppBar(title: Text(widget.aluno.cadastroValidado ? 'Turmas do Aluno' : 'Validar Cadastro')),
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
                  onPressed: _salvando || (!widget.aluno.cadastroValidado && !a.cadastroCompleto) ? null : _validar,
                  icon: const Icon(Icons.verified_user),
                  label: _salvando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(widget.aluno.cadastroValidado ? 'Salvar turmas' : 'Validar e incluir na turma'),
                ),
              ],
            ),
    );
  }
}
