import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../models/turma.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/presenca_repository.dart';
import '../../repositories/turma_repository.dart';
import '../../utils/date_utils.dart';
import '../../utils/turma_utils.dart';
import '../../widgets/aluno_avatar.dart';

/// Admin marca presença dos alunos em uma turma e data.
class ChamadaScreen extends StatefulWidget {
  final Turma? turmaInicial;
  const ChamadaScreen({super.key, this.turmaInicial});

  @override
  State<ChamadaScreen> createState() => _ChamadaScreenState();
}

class _ChamadaScreenState extends State<ChamadaScreen> {
  final _turmaRepo = TurmaRepository();
  final _alunoRepo = AlunoRepository();
  final _presRepo = PresencaRepository();

  List<Turma> _turmas = [];
  Turma? _turma;
  DateTime _data = DateTime.now();
  List<Aluno> _alunos = [];
  final Map<String, bool> _presentes = {};
  bool _loading = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _turma = widget.turmaInicial;
    _loadTurmas();
  }

  Future<void> _loadTurmas() async {
    setState(() => _loading = true);
    _turmas = await _turmaRepo.listar();
    if (_turma == null && _turmas.isNotEmpty) {
      _turma = _turmas.first;
    }
    await _carregarAlunosEPresencas();
  }

  String get _dataIso {
    final y = _data.year;
    final m = _data.month.toString().padLeft(2, '0');
    final d = _data.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _carregarAlunosEPresencas() async {
    if (_turma == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final ids = await _turmaRepo.alunoIdsPorTurma(_turma!.id);
      final alunos = await _alunoRepo.listarPorIds(ids);
      alunos.sort((a, b) => a.nome.compareTo(b.nome));
      final presencas = await _presRepo.porTurmaEData(_turma!.id, _dataIso);
      final mapaPres = {for (final p in presencas) p.alunoId: p.presente};

      _presentes.clear();
      for (final a in alunos) {
        _presentes[a.id] = mapaPres[a.id] ?? false;
      }

      if (mounted) {
        setState(() {
          _alunos = alunos;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _escolherData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => _data = picked);
      await _carregarAlunosEPresencas();
    }
  }

  Future<void> _salvar() async {
    if (_turma == null) return;
    setState(() => _salvando = true);
    try {
      final mapa = <String, ({String nome, bool presente})>{};
      for (final a in _alunos) {
        mapa[a.id] = (nome: a.nome, presente: _presentes[a.id] ?? false);
      }
      await _presRepo.salvarChamada(
        turmaId: _turma!.id,
        dataIso: _dataIso,
        porAluno: mapa,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chamada salva!'), backgroundColor: verdeEscuro),
        );
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

  int get _totalPresentes => _presentes.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamada / Presença'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarAlunosEPresencas),
        ],
      ),
      floatingActionButton: _turma != null && _alunos.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _salvando ? null : _salvar,
              backgroundColor: verdeEscuro,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(_salvando ? 'Salvando...' : 'Salvar chamada', style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Turma>(
                  value: _turma,
                  decoration: const InputDecoration(labelText: 'Turma', isDense: true),
                  items: _turmas
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.nome, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (t) async {
                    setState(() => _turma = t);
                    await _carregarAlunosEPresencas();
                  },
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _escolherData,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data do treino ($hintDataCompleta)',
                      isDense: true,
                      suffixIcon: const Icon(Icons.calendar_today, size: 20),
                    ),
                    child: Text(formatDataBr(_dataIso)),
                  ),
                ),
                if (_turma != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${formatarHorarioTurma(_turma!.horario)} · ${formatarDiasSemana(_turma!.diasSemana)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (_alunos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_totalPresentes de ${_alunos.length} presentes',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: verdeEscuro),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          for (final a in _alunos) {
                            _presentes[a.id] = true;
                          }
                        }),
                        child: const Text('Marcar todos'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
                : _turma == null
                    ? const Center(child: Text('Nenhuma turma cadastrada.'))
                    : _alunos.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum aluno nesta turma.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            itemCount: _alunos.length,
                            itemBuilder: (_, i) {
                              final a = _alunos[i];
                              final presente = _presentes[a.id] ?? false;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: presente ? Colors.green.shade50 : null,
                                child: CheckboxListTile(
                                  value: presente,
                                  onChanged: (v) => setState(() => _presentes[a.id] = v ?? false),
                                  secondary: AlunoAvatar(fotoUrl: a.fotoUrl, nome: a.nome, radius: 20),
                                  title: Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    presente ? 'Presente' : 'Ausente',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: presente ? Colors.green.shade800 : Colors.grey.shade600,
                                    ),
                                  ),
                                  activeColor: verdeEscuro,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
