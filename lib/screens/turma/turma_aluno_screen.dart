import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../models/turma.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/turma_repository.dart';
import '../../utils/turma_utils.dart';
import '../../widgets/faixa_badge.dart';
import '../../widgets/aluno_avatar.dart';
import '../../widgets/presencas_aluno_card.dart';
import '../../widgets/checkin_aluno_card.dart';
import '../../repositories/presenca_repository.dart';
import '../../repositories/presenca_config_repository.dart';
import '../../models/presenca.dart';
import '../../models/presenca_config.dart';

class TurmaAlunoScreen extends StatefulWidget {
  const TurmaAlunoScreen({super.key});

  @override
  State<TurmaAlunoScreen> createState() => _TurmaAlunoScreenState();
}

class _TurmaAlunoScreenState extends State<TurmaAlunoScreen> {
  final _turmaRepo = TurmaRepository();
  final _alunoRepo = AlunoRepository();
  final _presRepo = PresencaRepository();
  final _configRepo = PresencaConfigRepository();

  List<Turma> _turmas = [];
  MetodoPresenca _metodoPresenca = MetodoPresenca.chamada;
  Map<String, int> _contagem = {};
  List<Turma> _minhasTurmas = [];
  List<Aluno> _colegas = [];
  List<Presenca> _presencas = [];
  int _presencasMes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final aluno = auth.alunoVinculado;
      final results = await Future.wait([
        _turmaRepo.listar(),
        _turmaRepo.contagemAlunosPorTurma(),
        _configRepo.obter(),
      ]);
      final turmas = results[0] as List<Turma>;
      final contagem = results[1] as Map<String, int>;
      final config = results[2] as PresencaConfig;

      List<Turma> minhas = [];
      List<Aluno> colegas = [];
      List<Presenca> presencas = [];
      var presencasMes = 0;
      if (aluno != null) {
        minhas = await _turmaRepo.turmasDoAluno(aluno.id);
        final idsColegas = <String>{};
        for (final t in minhas) {
          final ids = await _turmaRepo.alunoIdsPorTurma(t.id);
          idsColegas.addAll(ids);
        }
        idsColegas.remove(aluno.id);
        colegas = await _alunoRepo.listarPorIds(idsColegas.toList());
        final now = DateTime.now();
        presencas = await _presRepo.porAluno(aluno.id);
        presencasMes = await _presRepo.contarPresencasMes(aluno.id, now.month, now.year);
      }

      if (mounted) {
        setState(() {
          _turmas = turmas;
          _contagem = contagem;
          _minhasTurmas = minhas;
          _colegas = colegas;
          _presencas = presencas;
          _presencasMes = presencasMes;
          _metodoPresenca = config.metodo;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turmas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Divisão por turma', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Quantidade de alunos em cada turma', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  ..._turmas.map((t) {
                    final n = _contagem[t.id] ?? 0;
                    final minha = _minhasTurmas.any((m) => m.id == t.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: minha ? verdeEscuro.withValues(alpha: 0.06) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: minha ? verdeEscuro : Colors.grey.shade300,
                          child: Text('$n', style: TextStyle(
                            color: minha ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          )),
                        ),
                        title: Text(t.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${formatarHorarioTurma(t.horario)} · ${formatarDiasSemana(t.diasSemana)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: minha
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: verdeEscuro.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Minha', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: verdeEscuro)),
                              )
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  CheckinAlunoCard(metodo: _metodoPresenca),
                  const SizedBox(height: 12),
                  PresencasAlunoCard(
                    presencas: _presencas,
                    minhasTurmas: _minhasTurmas,
                    presencasMesAtual: _presencasMes,
                  ),
                  const SizedBox(height: 20),
                  const Text('Colegas da minha turma', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    _minhasTurmas.isEmpty
                        ? 'Você ainda não está em uma turma.'
                        : '${_colegas.length} aluno(s) na(s) sua(s) turma(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  if (_colegas.isEmpty && _minhasTurmas.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Nenhum outro aluno na sua turma no momento.', style: TextStyle(color: Colors.grey.shade600)),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: _colegas.map((c) => ListTile(
                          leading: AlunoAvatar(fotoUrl: c.fotoUrl, nome: c.nome, radius: 20),
                          title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: FaixaBadge(faixa: c.faixa, grau: c.grau),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
