import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/aviso.dart';
import '../../repositories/aviso_repository.dart';

class AvisosScreen extends StatefulWidget {
  const AvisosScreen({super.key});
  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  final _repo = AvisoRepository();
  List<Aviso> _avisos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final lista = await _repo.listar(apenasAtivos: !isAdmin);
    if (mounted) setState(() { _avisos = lista; _loading = false; });
  }

  Future<void> _deletar(Aviso a) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(content: Text('Remover "${a.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ]));
    if (ok == true) { await _repo.deletar(a.id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('Quadro de Avisos'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _AvisoSheet(onSaved: _load));
        },
        backgroundColor: verdeEscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Aviso', style: TextStyle(color: Colors.white)),
      ) : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : _avisos.isEmpty
              ? const Center(child: Text('Nenhum aviso no momento.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom + 80),
                    itemCount: _avisos.length,
                    itemBuilder: (_, i) => _AvisoCard(
                      aviso: _avisos[i],
                      isAdmin: isAdmin,
                      onEdit: isAdmin ? () async {
                        await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => _AvisoSheet(aviso: _avisos[i], onSaved: _load));
                      } : null,
                      onDelete: isAdmin ? () => _deletar(_avisos[i]) : null,
                    ),
                  ),
                ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  final Aviso aviso;
  final bool isAdmin;
  final VoidCallback? onEdit, onDelete;
  const _AvisoCard({required this.aviso, required this.isAdmin, this.onEdit, this.onDelete});

  static const _config = {
    'info':       {'icon': Icons.info_outline,       'cor': Colors.blue},
    'alerta':     {'icon': Icons.warning_amber_outlined, 'cor': Colors.orange},
    'importante': {'icon': Icons.error_outline,      'cor': Colors.red},
    'bjj_news':   {'icon': Icons.newspaper,          'cor': Colors.purple},
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[aviso.tipo] ?? _config['info']!;
    final Color cor = cfg['cor'] as Color;
    final IconData icon = cfg['icon'] as IconData;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: aviso.ativo ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: cor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(aviso.titulo,
                  style: TextStyle(fontWeight: FontWeight.w800, color: cor))),
              if (aviso.tipo == 'bjj_news')
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text('BJJ News', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold))),
              if (!aviso.ativo)
                const Chip(label: Text('Inativo', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
              if (isAdmin) ...[
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ]),
            const SizedBox(height: 6),
            Text(aviso.conteudo, style: const TextStyle(fontSize: 13)),
            if (aviso.fonte != null) ...[
              const SizedBox(height: 4),
              Text('Fonte: ${aviso.fonte}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
            ],
            if (aviso.linkUrl != null && aviso.linkUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(aviso.linkUrl!);
                  if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: cor.withValues(alpha: 0.1),
                      border: Border.all(color: cor.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.open_in_new, size: 14, color: cor),
                    const SizedBox(width: 6),
                    Text('Ver mais / Fonte da notícia', style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _AvisoSheet extends StatefulWidget {
  final Aviso? aviso;
  final VoidCallback onSaved;
  const _AvisoSheet({this.aviso, required this.onSaved});
  @override
  State<_AvisoSheet> createState() => _AvisoSheetState();
}

class _AvisoSheetState extends State<_AvisoSheet> {
  final _repo = AvisoRepository();
  final _uuid = const Uuid();
  late final _tituloCtrl = TextEditingController(text: widget.aviso?.titulo ?? '');
  late final _conteudoCtrl = TextEditingController(text: widget.aviso?.conteudo ?? '');
  late final _linkCtrl = TextEditingController(text: widget.aviso?.linkUrl ?? '');
  late final _fonteCtrl = TextEditingController(text: widget.aviso?.fonte ?? '');
  String _tipo = 'info';
  bool _ativo = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.aviso != null) {
      _tipo = widget.aviso!.tipo;
      _ativo = widget.aviso!.ativo;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose(); _conteudoCtrl.dispose(); _linkCtrl.dispose(); _fonteCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_tituloCtrl.text.trim().isEmpty || _conteudoCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final a = Aviso(
      id: widget.aviso?.id ?? _uuid.v4(),
      titulo: _tituloCtrl.text.trim(),
      conteudo: _conteudoCtrl.text.trim(),
      tipo: _tipo,
      linkUrl: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      fonte: _fonteCtrl.text.trim().isEmpty ? null : _fonteCtrl.text.trim(),
      ativo: _ativo,
      createdAt: widget.aviso?.createdAt,
    );
    if (widget.aviso != null) { await _repo.atualizar(a); } else { await _repo.criar(a); }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.aviso != null ? 'Editar Aviso' : 'Novo Aviso',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipo,
          decoration: const InputDecoration(labelText: 'Tipo', isDense: true),
          items: const [
            DropdownMenuItem(value: 'info', child: Text('ℹ️ Informação')),
            DropdownMenuItem(value: 'alerta', child: Text('⚠️ Alerta')),
            DropdownMenuItem(value: 'importante', child: Text('🚨 Importante')),
            DropdownMenuItem(value: 'bjj_news', child: Text('📰 Notícia BJJ')),
          ],
          onChanged: (v) => setState(() => _tipo = v!),
        ),
        const SizedBox(height: 12),
        TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título *', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: _conteudoCtrl, decoration: const InputDecoration(labelText: 'Conteúdo *', isDense: true), maxLines: 3),
        const SizedBox(height: 12),
        TextField(controller: _fonteCtrl,
            decoration: const InputDecoration(labelText: 'Fonte / Autor', hintText: 'Ex: CBJJ, BJJ Heroes...', isDense: true, prefixIcon: Icon(Icons.source_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _linkCtrl,
            decoration: const InputDecoration(labelText: 'Link (URL completa)', hintText: 'https://...', isDense: true, prefixIcon: Icon(Icons.link)),
            keyboardType: TextInputType.url),
        const SizedBox(height: 8),
        SwitchListTile(title: const Text('Visível para alunos'), value: _ativo,
            onChanged: (v) => setState(() => _ativo = v), activeColor: verdeEscuro, contentPadding: EdgeInsets.zero),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _salvar,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.aviso != null ? 'Salvar' : 'Publicar'),
        ),
      ])),
    );
  }
}
