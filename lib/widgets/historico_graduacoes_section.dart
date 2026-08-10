import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../models/aluno.dart';
import '../models/graduacao.dart';
import '../repositories/aluno_repository.dart';
import '../repositories/graduacao_repository.dart';
import '../utils/bjj_utils.dart';
import '../utils/date_utils.dart';
import 'faixa_badge.dart';

String labelFaixa(String faixa) =>
    faixa.isEmpty ? '—' : '${faixa[0].toUpperCase()}${faixa.substring(1)}';

String labelGrau(int grau) => grau <= 0 ? 'Sem grau' : '$grau° grau';

/// Histórico de graduações do aluno. Leitura para autenticados; CRUD só admin.
class HistoricoGraduacoesSection extends StatefulWidget {
  final String alunoId;
  final String alunoNome;
  final bool isAdmin;
  final String? faixaAtual;
  final int? grauAtual;
  final VoidCallback? onFaixaAtualizada;

  const HistoricoGraduacoesSection({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.isAdmin = false,
    this.faixaAtual,
    this.grauAtual,
    this.onFaixaAtualizada,
  });

  @override
  State<HistoricoGraduacoesSection> createState() => _HistoricoGraduacoesSectionState();
}

class _HistoricoGraduacoesSectionState extends State<HistoricoGraduacoesSection> {
  final _repo = GraduacaoRepository();
  List<Graduacao> _itens = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HistoricoGraduacoesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alunoId != widget.alunoId) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listarPorAluno(widget.alunoId);
      if (mounted) setState(() { _itens = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirForm({Graduacao? existente}) async {
    final result = await showDialog<_GraduacaoFormResult>(
      context: context,
      builder: (_) => _GraduacaoFormDialog(
        alunoNome: widget.alunoNome,
        existente: existente,
        faixaInicial: existente?.faixa ?? widget.faixaAtual ?? 'branca',
        grauInicial: existente?.grau ?? widget.grauAtual ?? 0,
      ),
    );
    if (result == null) return;

    try {
      if (existente == null) {
        await _repo.criar(Graduacao(
          id: const Uuid().v4(),
          alunoId: widget.alunoId,
          alunoNome: widget.alunoNome,
          dataGraduacao: result.dataIso,
          faixa: result.faixa,
          grau: result.grau,
          observacao: result.observacao,
          professor: result.professor,
          evento: result.evento,
          formadaAcademia: result.formadaAcademia,
        ));
      } else {
        await _repo.atualizar(Graduacao(
          id: existente.id,
          alunoId: widget.alunoId,
          alunoNome: widget.alunoNome,
          dataGraduacao: result.dataIso,
          faixa: result.faixa,
          grau: result.grau,
          observacao: result.observacao,
          professor: result.professor,
          evento: result.evento,
          formadaAcademia: result.formadaAcademia,
          createdAt: existente.createdAt,
        ));
      }

      if (result.atualizarFaixaAtual) {
        final aluno = await AlunoRepository().buscarPorId(widget.alunoId);
        if (aluno != null) {
          await AlunoRepository().atualizar(aluno.copyWith(
            faixa: result.faixa,
            grau: result.grau,
          ));
          widget.onFaixaAtualizada?.call();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existente == null ? 'Graduação registrada.' : 'Graduação atualizada.')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _remover(Graduacao g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir graduação?'),
        content: Text('${labelFaixa(g.faixa)} · ${labelGrau(g.grau)}\n${formatDataBr(g.dataGraduacao)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.remover(g.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histórico de graduações',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Todas as faixas importam — da mais recente à mais antiga.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.25),
                  ),
                ],
              ),
            ),
            if (widget.isAdmin)
              TextButton.icon(
                onPressed: () => _abrirForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Registrar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: verdeEscuro)),
          )
        else if (_itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              widget.isAdmin
                  ? 'Nenhuma graduação registrada. Toque em Registrar para adicionar qualquer faixa.'
                  : 'Nenhuma graduação registrada ainda.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          )
        else
          ...List.generate(_itens.length, (i) {
            final g = _itens[i];
            return _GraduacaoTimelineTile(
              graduacao: g,
              isFirst: i == 0,
              isLast: i == _itens.length - 1,
              isAdmin: widget.isAdmin,
              onEdit: () => _abrirForm(existente: g),
              onDelete: () => _remover(g),
            );
          }),
      ],
    );
  }
}

class _GraduacaoTimelineTile extends StatelessWidget {
  final Graduacao graduacao;
  final bool isFirst;
  final bool isLast;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GraduacaoTimelineTile({
    required this.graduacao,
    required this.isFirst,
    required this.isLast,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final g = graduacao;
    final isPreta = g.faixa == 'preta';
    final smBjj = g.isPretaFormadaCasa;
    final corFaixa = getFaixaColor(g.faixa);
    final detalhes = <String>[
      if ((g.professor ?? '').trim().isNotEmpty) 'Prof. ${g.professor!.trim()}',
      if ((g.evento ?? '').trim().isNotEmpty) g.evento!.trim(),
    ];

    final borderColor = smBjj
        ? Colors.amber.shade700
        : isPreta
            ? Colors.grey.shade800
            : Colors.grey.shade300;
    final bgColor = smBjj
        ? const Color(0xFF111111)
        : isPreta
            ? const Color(0xFFF7F7F7)
            : Colors.white;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: corFaixa,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: smBjj
                          ? Colors.amber.shade600
                          : (g.faixa == 'branca' ? Colors.grey.shade500 : Colors.white),
                      width: smBjj ? 2.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.fromLTRB(12, 12, isAdmin ? 4 : 12, 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: smBjj || isPreta ? 1.4 : 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FaixaIlustracao(faixa: g.faixa, grau: g.grau, width: 72, height: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${labelFaixa(g.faixa)} · ${labelGrau(g.grau)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: smBjj ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDataBr(g.dataGraduacao),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: smBjj ? Colors.amber.shade200 : Colors.grey.shade700,
                          ),
                        ),
                        if (isPreta) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _Badge(
                                label: 'Faixa-preta',
                                bg: smBjj ? Colors.grey.shade900 : Colors.black,
                                fg: smBjj ? Colors.amber.shade300 : Colors.white,
                                border: smBjj ? Colors.amber.shade700 : null,
                              ),
                              if (smBjj)
                                _Badge(
                                  label: 'Faixa-preta SM BJJ',
                                  bg: Colors.amber.shade700,
                                  fg: Colors.black,
                                ),
                            ],
                          ),
                        ],
                        if (detalhes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            detalhes.join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              color: smBjj ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if ((g.observacao ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            g.observacao!.trim(),
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: smBjj ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isAdmin) ...[
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: smBjj ? Colors.amber.shade200 : verdeEscuro,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: smBjj ? Colors.red.shade200 : Colors.red,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Excluir',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _GraduacaoFormResult {
  final String dataIso;
  final String faixa;
  final int grau;
  final String? observacao;
  final String? professor;
  final String? evento;
  final bool formadaAcademia;
  final bool atualizarFaixaAtual;

  const _GraduacaoFormResult({
    required this.dataIso,
    required this.faixa,
    required this.grau,
    this.observacao,
    this.professor,
    this.evento,
    this.formadaAcademia = false,
    this.atualizarFaixaAtual = false,
  });
}

class _GraduacaoFormDialog extends StatefulWidget {
  final String alunoNome;
  final Graduacao? existente;
  final String faixaInicial;
  final int grauInicial;

  const _GraduacaoFormDialog({
    required this.alunoNome,
    this.existente,
    required this.faixaInicial,
    required this.grauInicial,
  });

  @override
  State<_GraduacaoFormDialog> createState() => _GraduacaoFormDialogState();
}

class _GraduacaoFormDialogState extends State<_GraduacaoFormDialog> {
  late final TextEditingController _dataCtrl;
  late final TextEditingController _obsCtrl;
  late final TextEditingController _profCtrl;
  late final TextEditingController _eventoCtrl;
  late String _faixa;
  late int _grau;
  late bool _formadaAcademia;
  late bool _atualizarFaixaAtual;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _dataCtrl = TextEditingController(
      text: e != null ? formatDataBr(e.dataGraduacao) : '',
    );
    _obsCtrl = TextEditingController(text: e?.observacao ?? '');
    _profCtrl = TextEditingController(text: e?.professor ?? '');
    _eventoCtrl = TextEditingController(text: e?.evento ?? '');
    _faixa = e?.faixa ?? widget.faixaInicial;
    _grau = e?.grau ?? widget.grauInicial;
    _formadaAcademia = e?.formadaAcademia == true && _faixa == 'preta';
    _atualizarFaixaAtual = e == null;
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    _obsCtrl.dispose();
    _profCtrl.dispose();
    _eventoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final atual = parseDataCompleta(_dataCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: verdeEscuro),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dataCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  void _salvar() {
    final iso = dataCompletaParaIso(_dataCtrl.text);
    if (iso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a data da graduação ($hintDataCompleta).')),
      );
      return;
    }
    Navigator.pop(
      context,
      _GraduacaoFormResult(
        dataIso: iso,
        faixa: _faixa,
        grau: _grau,
        observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
        professor: _profCtrl.text.trim().isEmpty ? null : _profCtrl.text.trim(),
        evento: _eventoCtrl.text.trim().isEmpty ? null : _eventoCtrl.text.trim(),
        formadaAcademia: _formadaAcademia && _faixa == 'preta',
        atualizarFaixaAtual: _atualizarFaixaAtual,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.existente != null;
    return AlertDialog(
      title: Text(editando ? 'Editar graduação' : 'Registrar graduação'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.alunoNome, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            TextField(
              controller: _dataCtrl,
              decoration: InputDecoration(
                labelText: 'Data da graduação *',
                hintText: hintDataCompleta,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _pickData,
                ),
              ),
              readOnly: true,
              onTap: _pickData,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _faixa,
              decoration: const InputDecoration(labelText: 'Faixa'),
              items: faixas
                  .map((f) => DropdownMenuItem(value: f, child: Text(labelFaixa(f))))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _faixa = v;
                  if (v != 'preta') _formadaAcademia = false;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _grau,
              decoration: const InputDecoration(labelText: 'Graus (stripes)'),
              items: [0, 1, 2, 3, 4]
                  .map((g) => DropdownMenuItem(value: g, child: Text(labelGrau(g))))
                  .toList(),
              onChanged: (v) => setState(() => _grau = v ?? 0),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _profCtrl,
              decoration: const InputDecoration(labelText: 'Professor (opcional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _eventoCtrl,
              decoration: const InputDecoration(labelText: 'Evento / cerimônia (opcional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _obsCtrl,
              decoration: const InputDecoration(labelText: 'Observação (opcional)'),
              maxLines: 2,
            ),
            if (_faixa == 'preta')
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Faixa-preta SM BJJ'),
                subtitle: const Text('Formado(a) pela academia'),
                value: _formadaAcademia,
                activeColor: verdeEscuro,
                onChanged: (v) => setState(() => _formadaAcademia = v),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Atualizar faixa atual do aluno'),
              subtitle: const Text('Sincroniza faixa/grau no cadastro'),
              value: _atualizarFaixaAtual,
              activeColor: verdeEscuro,
              onChanged: (v) => setState(() => _atualizarFaixaAtual = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}

/// Atalho para admin abrir o formulário a partir da lista de alunos.
Future<void> registrarGraduacaoAluno(BuildContext context, Aluno aluno) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Graduações — ${aluno.nome}')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HistoricoGraduacoesSection(
              alunoId: aluno.id,
              alunoNome: aluno.nome,
              isAdmin: true,
              faixaAtual: aluno.faixa,
              grauAtual: aluno.grau,
            ),
          ),
        ),
      ),
    ),
  );
}
