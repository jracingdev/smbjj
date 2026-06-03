import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/aluno.dart';
import '../../models/mensalidade.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/mensalidade_repository.dart';
import '../../repositories/aviso_repository.dart';
import '../../repositories/evento_repository.dart';
import '../../models/aviso.dart';
import 'avisos_screen.dart';
import 'calendario_screen.dart';
import '../../models/evento.dart';
import '../../utils/bjj_utils.dart';
import '../../widgets/faixa_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _alunoRepo = AlunoRepository();
  final _mensRepo = MensalidadeRepository();
  final _avisoRepo = AvisoRepository();
  final _eventoRepo = EventoRepository();

  List<Aluno> _alunos = [];
  List<Mensalidade> _mensalidades = [];
  List<Aviso> _avisos = [];
  List<Evento> _eventos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final results = await Future.wait([
      _alunoRepo.listar(),
      _mensRepo.listar(mes: now.month, ano: now.year),
      _avisoRepo.listar(apenasAtivos: !context.read<AuthProvider>().isAdmin),
      _eventoRepo.listar(),
    ]);
    if (mounted) {
      setState(() {
        _alunos = results[0] as List<Aluno>;
        _mensalidades = results[1] as List<Mensalidade>;
        _avisos = results[2] as List<Aviso>;
        _eventos = results[3] as List<Evento>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.sports_martial_arts, color: Colors.white),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SM BJJ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text(isAdmin ? 'Painel Admin' : 'Bem-vindo!', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : RefreshIndicator(
              onRefresh: _load,
              child: isAdmin ? _buildAdmin() : _buildAluno(),
            ),
    );
  }

  Widget _buildAdmin() {
    final now = DateTime.now();
    final ativos = _alunos.where((a) => a.ativo).length;
    final pagos = _mensalidades.where((m) => m.status == 'pago').toList();
    final pendentes = _mensalidades.where((m) => m.status != 'pago').length;
    final totalArrecadado = pagos.fold(0.0, (s, m) => s + m.valor);
    final pendentesValidacao = _alunos.where((a) => !a.cadastroValidado).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${meses[now.month - 1]} de ${now.year}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 12),

        if (pendentesValidacao > 0)
          _AlertaBanner(
            icon: Icons.shield_outlined,
            texto: '$pendentesValidacao cadastro(s) aguardando validação',
            cor: Colors.amber,
          ),

        // Cards de stats
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _StatCard(icon: Icons.people, label: 'Alunos Ativos', value: '$ativos', cor: Colors.green),
            _StatCard(icon: Icons.attach_money, label: 'Arrecadado', value: 'R\$ ${totalArrecadado.toStringAsFixed(2)}', cor: Colors.blue),
            _StatCard(icon: Icons.pending_actions, label: 'Pendentes', value: '$pendentes', cor: Colors.orange),
            _StatCard(icon: Icons.emoji_events, label: 'Total Alunos', value: '${_alunos.length}', cor: Colors.purple),
          ],
        ),
        const SizedBox(height: 20),

        // Alunos recentes
        _SectionTitle('Alunos Recentes'),
        Card(
          child: Column(
            children: _alunos.where((a) => a.ativo).take(5).map((a) => ListTile(
              leading: CircleAvatar(
                backgroundColor: verdeEscuro,
                child: Text(a.nome[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${getCategoriaEtaria(a.dataNascimento)} · ${a.sexo}'),
              trailing: FaixaBadge(faixa: a.faixa, grau: a.grau),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),

        _SectionTitle('Quadro de Avisos'),
        _AvisosCard(avisos: _avisos),
        const SizedBox(height: 20),

        _SectionTitle('Calendário da Equipe'),
        _EventosCard(eventos: _eventos),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAluno() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Avisos'),
        _AvisosCard(avisos: _avisos),
        const SizedBox(height: 20),
        _SectionTitle('Próximos Eventos'),
        _EventosCard(eventos: _eventos),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color cor;
  const _StatCard({required this.icon, required this.label, required this.value, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: cor, size: 20),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }
}

class _AlertaBanner extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color cor;
  const _AlertaBanner({required this.icon, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        border: Border.all(color: cor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: cor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: TextStyle(color: cor.shade700, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _AvisosCard extends StatelessWidget {
  final List<Aviso> avisos;
  const _AvisosCard({required this.avisos});

  static const _cores = {
    'alerta': Colors.orange, 'importante': Colors.red,
    'bjj_news': Colors.purple,
  };
  static const _icons = {
    'alerta': Icons.warning_amber_outlined, 'importante': Icons.error_outline,
    'bjj_news': Icons.newspaper,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: [
        if (avisos.isEmpty)
          Padding(padding: const EdgeInsets.all(20),
            child: Center(child: Text('Nenhum aviso no momento.', style: TextStyle(color: Colors.grey.shade500))))
        else
          ...avisos.take(3).map((a) {
            final cor = _cores[a.tipo] ?? Colors.blue;
            final icon = _icons[a.tipo] ?? Icons.info_outline;
            return ListTile(
              leading: Icon(icon, color: cor),
              title: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.conteudo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                if (a.linkUrl != null && a.linkUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(a.linkUrl!);
                      if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Text('🔗 Ver mais', style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
                  ),
              ]),
            );
          }),
        ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvisosScreen())),
          title: const Text('Ver todos os avisos', style: TextStyle(color: verdeEscuro, fontWeight: FontWeight.w600, fontSize: 13)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: verdeEscuro),
        ),
      ]),
    );
  }
}

class _EventosCard extends StatelessWidget {
  final List<Evento> eventos;
  const _EventosCard({required this.eventos});

  @override
  Widget build(BuildContext context) {
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final proximos = eventos.where((e) => e.data.compareTo(hoje) >= 0).take(3).toList();

    return Card(
      child: Column(children: [
        if (proximos.isEmpty)
          Padding(padding: const EdgeInsets.all(20),
            child: Center(child: Text('Nenhum evento próximo.', style: TextStyle(color: Colors.grey.shade500))))
        else
          ...proximos.map((e) {
            IconData icon; Color cor;
            switch (e.tipo) {
              case 'campeonato': icon = Icons.emoji_events; cor = const Color(0xFFD4A017); break;
              case 'seminario': icon = Icons.menu_book; cor = Colors.blue; break;
              case 'graduacao': icon = Icons.military_tech; cor = Colors.purple; break;
              case 'aulao': icon = Icons.people; cor = Colors.green; break;
              case 'bjj_news': icon = Icons.newspaper; cor = Colors.teal; break;
              default: icon = Icons.event; cor = Colors.grey;
            }
            return ListTile(
              leading: Icon(icon, color: cor),
              title: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.data}${e.local != null ? ' · ${e.local}' : ''}', style: const TextStyle(fontSize: 12)),
                if (e.linkUrl != null && e.linkUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(e.linkUrl!);
                      if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Text('🔗 Inscrições / Mais info', style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
                  ),
              ]),
            );
          }),
        ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarioScreen())),
          title: const Text('Ver calendário completo', style: TextStyle(color: verdeEscuro, fontWeight: FontWeight.w600, fontSize: 13)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: verdeEscuro),
        ),
      ]),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}
