import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/evento.dart';
import '../../repositories/evento_repository.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});
  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> with SingleTickerProviderStateMixin {
  final _repo = EventoRepository();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Evento> _eventos = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lista = await _repo.listar();
    if (mounted) setState(() { _eventos = lista; _loading = false; });
  }

  Future<void> _deletar(Evento e) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(content: Text('Remover "${e.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ]));
    if (ok == true) { await _repo.deletar(e.id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final proximos = _eventos.where((e) => e.data.compareTo(hoje) >= 0).toList();
    final passados = _eventos.where((e) => e.data.compareTo(hoje) < 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário da Equipe'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.event_available, size: 18), text: 'Próximos'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'Passados'),
          ],
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _EventoSheet(onSaved: _load));
        },
        backgroundColor: verdeEscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Evento', style: TextStyle(color: Colors.white)),
      ) : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : TabBarView(controller: _tabs, children: [
              _listaEventos(proximos, isAdmin, false),
              _listaEventos(passados, isAdmin, true),
            ]),
    );
  }

  Widget _listaEventos(List<Evento> lista, bool isAdmin, bool passados) {
    if (lista.isEmpty) {
      return Center(child: Text(passados ? 'Nenhum evento passado.' : 'Nenhum evento próximo.',
          style: TextStyle(color: Colors.grey.shade500)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom + 80),
        itemCount: lista.length,
        itemBuilder: (_, i) => _EventoCard(
          evento: lista[i],
          isAdmin: isAdmin,
          dimmed: passados,
          onEdit: isAdmin ? () async {
            await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _EventoSheet(evento: lista[i], onSaved: _load));
          } : null,
          onDelete: isAdmin ? () => _deletar(lista[i]) : null,
        ),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Evento evento;
  final bool isAdmin, dimmed;
  final VoidCallback? onEdit, onDelete;
  const _EventoCard({required this.evento, required this.isAdmin, this.dimmed = false, this.onEdit, this.onDelete});

  static const _tipos = {
    'campeonato': {'icon': Icons.emoji_events,   'cor': Color(0xFFD4A017), 'label': 'Campeonato'},
    'seminario':  {'icon': Icons.menu_book,       'cor': Colors.blue,       'label': 'Seminário'},
    'aulao':      {'icon': Icons.people,          'cor': Colors.green,      'label': 'Aulão'},
    'graduacao':  {'icon': Icons.military_tech,   'cor': Colors.purple,     'label': 'Graduação'},
    'bjj_news':   {'icon': Icons.newspaper,       'cor': Colors.teal,       'label': 'Notícia BJJ'},
    'outro':      {'icon': Icons.event,           'cor': Colors.grey,       'label': 'Outro'},
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _tipos[evento.tipo] ?? _tipos['outro']!;
    final Color cor = cfg['cor'] as Color;
    final IconData icon = cfg['icon'] as IconData;
    final String label = cfg['label'] as String;

    String dataFormatada;
    try {
      dataFormatada = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(DateTime.parse(evento.data));
    } catch (_) {
      dataFormatada = evento.data;
    }

    return Opacity(
      opacity: dimmed ? 0.65 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: cor, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('$label · $dataFormatada', style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
              ])),
              if (isAdmin) ...[
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ]),
            if (evento.local != null || evento.organizador != null) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 12, children: [
                if (evento.local != null) Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(evento.local!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                if (evento.organizador != null) Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.group_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(evento.organizador!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ]),
            ],
            if (evento.descricao != null) ...[
              const SizedBox(height: 6),
              Text(evento.descricao!, style: const TextStyle(fontSize: 13)),
            ],
            if (evento.linkUrl != null && evento.linkUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(evento.linkUrl!);
                  if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: cor.withValues(alpha: 0.1),
                      border: Border.all(color: cor.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.open_in_new, size: 14, color: cor),
                    const SizedBox(width: 6),
                    Text('Mais informações / Inscrições', style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
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

class _EventoSheet extends StatefulWidget {
  final Evento? evento;
  final VoidCallback onSaved;
  const _EventoSheet({this.evento, required this.onSaved});
  @override
  State<_EventoSheet> createState() => _EventoSheetState();
}

class _EventoSheetState extends State<_EventoSheet> {
  final _repo = EventoRepository();
  final _uuid = const Uuid();
  late final _tituloCtrl = TextEditingController(text: widget.evento?.titulo ?? '');
  late final _dataCtrl = TextEditingController(text: widget.evento?.data ?? '');
  late final _descCtrl = TextEditingController(text: widget.evento?.descricao ?? '');
  late final _localCtrl = TextEditingController(text: widget.evento?.local ?? '');
  late final _orgCtrl = TextEditingController(text: widget.evento?.organizador ?? '');
  late final _linkCtrl = TextEditingController(text: widget.evento?.linkUrl ?? '');
  String _tipo = 'campeonato';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.evento != null) _tipo = widget.evento!.tipo;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose(); _dataCtrl.dispose(); _descCtrl.dispose();
    _localCtrl.dispose(); _orgCtrl.dispose(); _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _dataCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _salvar() async {
    if (_tituloCtrl.text.trim().isEmpty || _dataCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final e = Evento(
      id: widget.evento?.id ?? _uuid.v4(),
      titulo: _tituloCtrl.text.trim(),
      data: _dataCtrl.text,
      tipo: _tipo,
      descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      local: _localCtrl.text.trim().isEmpty ? null : _localCtrl.text.trim(),
      organizador: _orgCtrl.text.trim().isEmpty ? null : _orgCtrl.text.trim(),
      linkUrl: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      createdAt: widget.evento?.createdAt,
    );
    if (widget.evento != null) { await _repo.atualizar(e); } else { await _repo.criar(e); }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.evento != null ? 'Editar Evento' : 'Novo Evento',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipo,
          decoration: const InputDecoration(labelText: 'Tipo', isDense: true),
          items: const [
            DropdownMenuItem(value: 'campeonato', child: Text('🏆 Campeonato')),
            DropdownMenuItem(value: 'seminario',  child: Text('📚 Seminário')),
            DropdownMenuItem(value: 'aulao',      child: Text('👥 Aulão')),
            DropdownMenuItem(value: 'graduacao',  child: Text('🥋 Graduação')),
            DropdownMenuItem(value: 'bjj_news',   child: Text('📰 Notícia BJJ')),
            DropdownMenuItem(value: 'outro',      child: Text('📌 Outro')),
          ],
          onChanged: (v) => setState(() => _tipo = v!),
        ),
        const SizedBox(height: 12),
        TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título *', isDense: true)),
        const SizedBox(height: 12),
        TextField(
          controller: _dataCtrl,
          readOnly: true,
          onTap: _pickData,
          decoration: InputDecoration(
            labelText: 'Data *',
            isDense: true,
            suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickData),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _localCtrl, decoration: const InputDecoration(labelText: 'Local', isDense: true, prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _orgCtrl, decoration: const InputDecoration(labelText: 'Organizador / Federação', isDense: true, prefixIcon: Icon(Icons.group_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descrição / Detalhes', isDense: true), maxLines: 2),
        const SizedBox(height: 12),
        TextField(controller: _linkCtrl,
            decoration: const InputDecoration(labelText: 'Link (inscrições, notícia, etc.)', hintText: 'https://...', isDense: true, prefixIcon: Icon(Icons.link)),
            keyboardType: TextInputType.url),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _salvar,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.evento != null ? 'Salvar' : 'Adicionar Evento'),
        ),
      ])),
    );
  }
}
