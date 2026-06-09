import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../models/medalha.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/medalha_repository.dart';
import '../../utils/medalha_ranking.dart';
import '../../widgets/mes_ano_picker.dart';

class MedalhasAdminScreen extends StatefulWidget {
  const MedalhasAdminScreen({super.key});

  @override
  State<MedalhasAdminScreen> createState() => _MedalhasAdminScreenState();
}

class _MedalhasAdminScreenState extends State<MedalhasAdminScreen> {
  final _medalhaRepo = MedalhaRepository();
  final _alunoRepo = AlunoRepository();
  final _uuid = const Uuid();

  List<Medalha> _medalhas = [];
  List<Aluno> _alunos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _medalhaRepo.listar(apenasAtivas: false),
        _alunoRepo.listar(ativo: true),
      ]);
      if (mounted) {
        setState(() {
          _medalhas = results[0] as List<Medalha>;
          _alunos = (results[1] as List<Aluno>).where((a) => a.cadastroValidado).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _adicionar() async {
    if (_alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum aluno validado para medalha.')),
      );
      return;
    }

    Aluno? alunoSel = _alunos.first;
    final tituloCtrl = TextEditingController();
    String tipo = 'ouro';
    String? dataConquista;

    String? tituloSalvo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Nova medalha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Aluno>(
                  value: alunoSel,
                  decoration: const InputDecoration(labelText: 'Aluno'),
                  items: _alunos
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.nome)))
                      .toList(),
                  onChanged: (v) => setD(() => alunoSel = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Medalha / Conquista *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'ouro', child: Text('Ouro')),
                    DropdownMenuItem(value: 'prata', child: Text('Prata')),
                    DropdownMenuItem(value: 'bronze', child: Text('Bronze')),
                    DropdownMenuItem(value: 'outro', child: Text('Outro')),
                  ],
                  onChanged: (v) => setD(() => tipo = v ?? 'ouro'),
                ),
                const SizedBox(height: 8),
                MesAnoPicker(
                  label: 'Data da conquista',
                  value: dataConquista,
                  onChanged: (v) => setD(() => dataConquista = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (tituloCtrl.text.trim().isEmpty) return;
                tituloSalvo = tituloCtrl.text.trim();
                Navigator.pop(ctx, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    tituloCtrl.dispose();
    if (ok != true || alunoSel == null || tituloSalvo == null) return;

    await _medalhaRepo.criar(Medalha(
      id: _uuid.v4(),
      alunoId: alunoSel!.id,
      alunoNome: alunoSel!.nome,
      titulo: tituloSalvo!,
      tipo: tipo,
      dataConquista: dataConquista,
    ));
    _load();
  }

  Future<void> _remover(Medalha m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover medalha?'),
        content: Text('${m.alunoNome} — ${m.titulo}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _medalhaRepo.remover(m.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quadro de medalhas (Ranking interno)')),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionar,
        backgroundColor: verdeEscuro,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : RefreshIndicator(
              onRefresh: _load,
              child: _medalhas.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      Center(child: Text('Nenhuma medalha.', style: TextStyle(color: Colors.grey.shade600))),
                    ])
                  : Builder(
                      builder: (context) {
                        final ranking = calcularRankingMedalhas(_medalhas);
                        final porAluno = agruparMedalhasPorAluno(_medalhas);

                        return ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            Text(
                              'Pontuação: ouro 5 · prata 2 · bronze 1',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 12),
                            ...ranking.asMap().entries.map((entry) {
                              final pos = entry.key + 1;
                              final r = entry.value;
                              final key = chaveAlunoMedalhaDados(alunoId: r.alunoId, alunoNome: r.alunoNome);
                              final medalhasAluno = porAluno[key] ?? [];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: pos <= 3 ? Colors.amber.shade100 : Colors.grey.shade200,
                                    child: Text(
                                      '$pos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: pos <= 3 ? Colors.amber.shade900 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  title: Text(r.alunoNome, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                    '${r.pontos} pts · ${r.total} medalha${r.total == 1 ? '' : 's'} · ${r.ouro}O ${r.prata}P ${r.bronze}B',
                                  ),
                                  children: medalhasAluno
                                      .map(
                                        (m) => ListTile(
                                          dense: true,
                                          leading: Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 20),
                                          title: Text(m.titulo),
                                          subtitle: Text('${m.tipo}${m.ativo ? '' : ' · inativa'}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _remover(m),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
    );
  }
}
