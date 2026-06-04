import 'package:flutter/material.dart';
import '../../utils/image_utils.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../repositories/aluno_repository.dart';
import '../../utils/bjj_utils.dart';
import '../../widgets/faixa_badge.dart';
import 'aluno_form_screen.dart';
import 'validar_aluno_screen.dart';
import '../turmas/turmas_screen.dart';
import '../../repositories/turma_repository.dart';
import '../../models/turma.dart';

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});

  @override
  AlunosScreenState createState() => AlunosScreenState();
}

class AlunosScreenState extends State<AlunosScreen> {
  final _repo = AlunoRepository();
  final _turmaRepo = TurmaRepository();
  List<Aluno> _alunos = [];
  List<Turma> _turmas = [];
  Map<String, List<Turma>> _turmasPorAluno = {};
  bool _loading = true;
  String _busca = '';
  String _filtroFaixa = '';
  String _filtroStatus = 'ativo';
  String _filtroTurma = '';

  /// Chamado pelo painel ou aba Alunos para exibir cadastros aguardando validação.
  void filtrarPendentes() => setState(() => _filtroStatus = 'pendente');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lista = await _repo.listar();
    final turmas = await _turmaRepo.listar();
    final map = <String, List<Turma>>{};
    for (final a in lista) {
      map[a.id] = await _turmaRepo.turmasDoAluno(a.id);
    }
    final qtdPendentes = lista.where((a) => !a.cadastroValidado).length;
    if (mounted) {
      setState(() {
        _alunos = lista;
        _turmas = turmas;
        _turmasPorAluno = map;
        _loading = false;
        // Cadastros novos ficam com ativo=false; filtro "Ativos" os escondia.
        if (qtdPendentes > 0 && _filtroStatus == 'ativo') {
          _filtroStatus = 'pendente';
        }
      });
    }
  }

  List<Aluno> get _filtrados {
    return _alunos.where((a) {
      final matchBusca = a.nome.toLowerCase().contains(_busca.toLowerCase());
      final matchFaixa = _filtroFaixa.isEmpty || a.faixa == _filtroFaixa;
      final matchStatus = _filtroStatus == 'todos'
          ? true
          : _filtroStatus == 'pendente'
              ? !a.cadastroValidado
              : _filtroStatus == 'ativo'
                  ? a.ativo
                  : !a.ativo;
      final turmasAluno = _turmasPorAluno[a.id] ?? [];
      final matchTurma = _filtroTurma.isEmpty || turmasAluno.any((t) => t.id == _filtroTurma);
      return matchBusca && matchFaixa && matchStatus && matchTurma;
    }).toList();
  }

  Future<void> _deletar(Aluno a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover Aluno'),
        content: Text('Remover ${a.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deletar(a.id);
      _load();
    }
  }

  Future<void> _validar(Aluno a) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ValidarAlunoScreen(aluno: a)),
    );
    if (ok == true) _load();
  }

  Future<void> _gerenciarTurmas(Aluno a) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ValidarAlunoScreen(aluno: a)),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _alunos.where((a) => !a.cadastroValidado).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alunos (${_alunos.where((a) => a.ativo).length} ativos)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Gerenciar turmas',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const TurmasScreen()));
              _load();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AlunoFormScreen()));
          _load();
        },
        backgroundColor: verdeEscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Aluno', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Banner pendentes
          if (pendentes > 0)
            Material(
              color: Colors.amber.shade50,
              child: InkWell(
                onTap: filtrarPendentes,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.shield_outlined, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$pendentes cadastro(s) aguardando validação — toque para ver',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.amber.shade800, size: 20),
                  ]),
                ),
              ),
            ),

          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar aluno...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _busca = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroFaixa.isEmpty ? '' : _filtroFaixa,
                    decoration: const InputDecoration(labelText: 'Faixa', isDense: true),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todas')),
                      ...faixas.map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1)))),
                    ],
                    onChanged: (v) => setState(() => _filtroFaixa = v ?? ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroStatus,
                    decoration: const InputDecoration(labelText: 'Status', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'ativo', child: Text('Ativos')),
                      DropdownMenuItem(value: 'pendente', child: Text('Pendentes')),
                      DropdownMenuItem(value: 'inativo', child: Text('Inativos')),
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    ],
                    onChanged: (v) => setState(() => _filtroStatus = v ?? 'ativo'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _filtroTurma.isEmpty ? '' : _filtroTurma,
                decoration: const InputDecoration(labelText: 'Turma', isDense: true),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas as turmas')),
                  ..._turmas.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome))),
                ],
                onChanged: (v) => setState(() => _filtroTurma = v ?? ''),
              ),
            ]),
          ),

          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
                : _filtrados.isEmpty
                    ? Center(child: Text('Nenhum aluno encontrado.', style: TextStyle(color: Colors.grey.shade500)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) => _AlunoCard(
                            aluno: _filtrados[i],
                            turmas: _turmasPorAluno[_filtrados[i].id] ?? [],
                            onEdit: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => AlunoFormScreen(aluno: _filtrados[i])));
                              _load();
                            },
                            onDelete: () => _deletar(_filtrados[i]),
                            onValidar: !_filtrados[i].cadastroValidado ? () => _validar(_filtrados[i]) : null,
                            onTurmas: _filtrados[i].cadastroValidado ? () => _gerenciarTurmas(_filtrados[i]) : null,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  final Aluno aluno;
  final List<Turma> turmas;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onValidar;
  final VoidCallback? onTurmas;

  const _AlunoCard({
    required this.aluno,
    required this.turmas,
    required this.onEdit,
    required this.onDelete,
    this.onValidar,
    this.onTurmas,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = getCategoriaEtaria(aluno.dataNascimento);
    final idade = calcularIdadeCBJJ(aluno.dataNascimento);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: aluno.ativo ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AlunoAvatar(fotoUrl: aluno.fotoUrl, nome: aluno.nome, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('$categoria${idade != null ? ' · $idade anos' : ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ]),
                  ),
                  FaixaBadge(faixa: aluno.faixa, grau: aluno.grau),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                if (!aluno.ativo) _chip('Inativo', Colors.grey),
                if (!aluno.cadastroValidado) _chip('Pendente', Colors.amber) else _chip('Validado', Colors.green),
                if (!aluno.cadastroCompleto && !aluno.cadastroValidado) _chip('Incompleto', Colors.red.shade100, textColor: Colors.red.shade800),
                ...turmas.map((t) => _chip(t.nome, Colors.teal.shade100, textColor: Colors.teal.shade900)),
                if (aluno.telefone != null) _chip(aluno.telefone!, Colors.blue.shade100, textColor: Colors.blue.shade800),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                if (onValidar != null)
                  Expanded(child: OutlinedButton.icon(
                    onPressed: onValidar,
                    icon: const Icon(Icons.verified_user_outlined, size: 16),
                    label: const Text('Validar'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.amber.shade700, side: BorderSide(color: Colors.amber.shade300)),
                  )),
                if (onValidar != null) const SizedBox(width: 8),
                if (onTurmas != null)
                  IconButton(
                    onPressed: onTurmas,
                    icon: const Icon(Icons.groups, color: verdeEscuro),
                    tooltip: 'Turmas',
                  ),
                Expanded(child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(foregroundColor: verdeEscuro, side: const BorderSide(color: verdeEscuro)),
                )),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, {Color? textColor}) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: textColor ?? Colors.black87)),
      backgroundColor: bg is MaterialColor ? bg.shade100 : bg,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AlunoAvatar extends StatelessWidget {
  final String? fotoUrl;
  final String nome;
  final double radius;
  const _AlunoAvatar({required this.fotoUrl, required this.nome, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      final isRemote = fotoUrl!.startsWith('http') || fotoUrl!.startsWith('blob:');
      final ImageProvider img = imageProviderFromPath(fotoUrl!);
      return CircleAvatar(radius: radius, backgroundImage: img,
          onBackgroundImageError: (_, __) {});
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: verdeEscuro,
      child: Text(nome[0].toUpperCase(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.8)),
    );
  }
}


