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
import '../../utils/scroll_padding.dart';
import '../../widgets/faixa_badge.dart';
import '../../widgets/turmas_aluno_card.dart';
import '../../widgets/contatos_card.dart';
import '../../widgets/turmas_grafico_card.dart';
import '../../widgets/quadro_medalhas_card.dart';
import '../../repositories/medalha_repository.dart';
import '../../models/medalha.dart';
import '../medalhas/medalhas_admin_screen.dart';
import '../../core/avisos/aviso_lido_service.dart';
import '../../core/medalhas/medalha_lido_service.dart';
import '../../core/aniversario/aniversario_aviso_service.dart';
import '../../utils/aniversario_utils.dart';
import '../../utils/date_utils.dart';
import '../presenca/presenca_admin_screen.dart';
import '../../repositories/turma_repository.dart';
import '../../models/turma.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onValidarPendentes;
  final VoidCallback? onAvisosLidos;
  const DashboardScreen({super.key, this.onValidarPendentes, this.onAvisosLidos});

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
  List<Turma> _minhasTurmas = [];
  List<Turma> _todasTurmas = [];
  Map<String, int> _contagemTurmas = {};
  List<Medalha> _medalhas = [];
  List<Aluno> _aniversariantesTurma = [];
  bool _mostrarAniversarioAviso = false;
  int _avisosNaoLidos = 0;
  int _medalhasNovas = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final isAdmin = context.read<AuthProvider>().isAdmin;
    try {
      if (isAdmin) {
        final turmaRepo = TurmaRepository();
        final results = await Future.wait([
          _alunoRepo.listar(),
          _mensRepo.listar(mes: now.month, ano: now.year),
          _avisoRepo.listar(apenasAtivos: false),
          _eventoRepo.listar(),
          turmaRepo.listar(apenasAtivas: false),
          turmaRepo.contagemAlunosPorTurma(),
          MedalhaRepository().listar(),
        ]);
        if (mounted) setState(() {
          _alunos = results[0] as List<Aluno>;
          _mensalidades = results[1] as List<Mensalidade>;
          _avisos = results[2] as List<Aviso>;
          _eventos = results[3] as List<Evento>;
          _todasTurmas = results[4] as List<Turma>;
          _contagemTurmas = results[5] as Map<String, int>;
          _medalhas = results[6] as List<Medalha>;
          _loading = false;
        });
      } else {
        final auth = context.read<AuthProvider>();
        final results = await Future.wait([
          _avisoRepo.listar(apenasAtivos: true),
          _eventoRepo.listar(),
          MedalhaRepository().listar(),
        ]);
        List<Turma> turmas = [];
        final aluno = auth.alunoVinculado;
        if (aluno != null) {
          turmas = await TurmaRepository().turmasDoAluno(aluno.id);
        }
        final avisos = results[0] as List<Aviso>;
        final medalhas = results[2] as List<Medalha>;
        final naoLidos = await AvisoLidoService().contarNaoLidos(avisos);
        final medalhasNovas = await MedalhaLidoService().contarNovas(medalhas);
        var aniversariantes = <Aluno>[];
        var mostrarAniversario = false;
        if (aluno != null) {
          aniversariantes = await carregarAniversariantesTurma(_alunoRepo, aluno.id);
          mostrarAniversario = await AniversarioAvisoService().avisoPendente(aniversariantes.length);
        }
        if (mounted) setState(() {
          _avisos = avisos;
          _eventos = results[1] as List<Evento>;
          _medalhas = medalhas;
          _minhasTurmas = turmas;
          _avisosNaoLidos = naoLidos;
          _medalhasNovas = medalhasNovas;
          _aniversariantesTurma = aniversariantes;
          _mostrarAniversarioAviso = mostrarAniversario;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
      padding: ScrollBottomPadding.all(context, extra: 24),
      children: [
        Text(formatMesAnoPartes(now.month, now.year), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 12),

        if (pendentesValidacao > 0)
          _AlertaBanner(
            icon: Icons.shield_outlined,
            texto: '$pendentesValidacao cadastro(s) aguardando validação — toque para validar',
            cor: Colors.amber,
            onTap: widget.onValidarPendentes,
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

        _SectionTitle('Alunos por Turma'),
        TurmasGraficoCard(turmas: _todasTurmas, contagem: _contagemTurmas),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: verdeEscuro,
              child: Icon(Icons.fact_check, color: Colors.white),
            ),
            title: const Text('Presença nos treinos', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Chamada manual, QR por turma ou QR único'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresencaAdminScreen())),
          ),
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

        _AvisosCard(avisos: _avisos, isAdmin: true, onRefresh: _load),
        const SizedBox(height: 20),

        _SectionTitle('Quadro de medalhas (Ranking interno)'),
        QuadroMedalhasCard(
          medalhas: _medalhas,
          isAdmin: true,
          onGerenciar: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const MedalhasAdminScreen()));
            _load();
          },
        ),
        const SizedBox(height: 20),

        _EventosCard(eventos: _eventos, isAdmin: true, onRefresh: _load),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAluno() {
    final aluno = context.watch<AuthProvider>().alunoVinculado;
    final mostraFaixa = aluno != null && aluno.cadastroValidado;

    return ListView(
      padding: ScrollBottomPadding.all(context, extra: 24),
      children: [
        if (mostraFaixa) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Minha graduação', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 12),
                  FaixaBadge(faixa: aluno.faixa, grau: aluno.grau),
                  const SizedBox(height: 8),
                  Text(
                    getCategoriaEtaria(aluno.dataNascimento),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_mostrarAniversarioAviso && _aniversariantesTurma.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () async {
                  await AniversarioAvisoService().marcarVistoHoje();
                  if (mounted) setState(() => _mostrarAniversarioAviso = false);
                  widget.onAvisosLidos?.call();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cake_outlined, color: Colors.pink.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aniversariante da turma!',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.pink.shade900, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _aniversariantesTurma.map((a) => a.nome.split(' ').first).join(', '),
                              style: TextStyle(fontSize: 13, color: Colors.pink.shade800),
                            ),
                            Text(
                              'Parabenize seu(s) colega(s) de treino hoje! Toque para marcar como visto.',
                              style: TextStyle(fontSize: 11, color: Colors.pink.shade700),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.close, size: 18, color: Colors.pink.shade400),
                    ],
                  ),
                ),
              ),
            ),
          ),
        _SectionTitle('Minha Turma'),
        TurmasAlunoCard(turmas: _minhasTurmas),
        const SizedBox(height: 20),
        _SectionTitle('Avisos'),
        if (_avisosNaoLidos > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const AvisosScreen()));
                  widget.onAvisosLidos?.call();
                  _load();
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_avisosNaoLidos novo(s) aviso(s)',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange.shade900, fontSize: 13),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.orange.shade700),
                    ],
                  ),
                ),
              ),
            ),
          ),
        _AvisosCard(avisos: _avisos, isAdmin: false, naoLidos: _avisosNaoLidos, onAvisosAbertos: () {
          widget.onAvisosLidos?.call();
          _load();
        }),
        const SizedBox(height: 20),
        _SectionTitle('Quadro de medalhas (Ranking interno)'),
        if (_medalhasNovas > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () async {
                  await MedalhaLidoService().marcarComoVisto();
                  if (mounted) setState(() => _medalhasNovas = 0);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Quadro de medalhas atualizado — toque para marcar como visto',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        QuadroMedalhasCard(medalhas: _medalhas),
        const SizedBox(height: 20),
        _SectionTitle('Próximos Eventos'),
        _EventosCard(eventos: _eventos, isAdmin: false),
        const SizedBox(height: 20),
        _SectionTitle('Fale conosco'),
        const ContatosCard(),
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
  final VoidCallback? onTap;
  const _AlertaBanner({required this.icon, required this.texto, required this.cor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Row(children: [
      Icon(icon, color: cor, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(texto, style: TextStyle(color: cor.shade700, fontWeight: FontWeight.w600, fontSize: 13))),
      if (onTap != null) Icon(Icons.chevron_right, color: cor.shade700, size: 20),
    ]);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        border: Border.all(color: cor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: onTap == null
          ? Padding(padding: const EdgeInsets.all(12), child: child)
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(padding: const EdgeInsets.all(12), child: child),
              ),
            ),
    );
  }
}

class _AvisosCard extends StatelessWidget {
  final List<Aviso> avisos;
  final bool isAdmin;
  final VoidCallback? onRefresh;
  final int naoLidos;
  final VoidCallback? onAvisosAbertos;
  const _AvisosCard({
    required this.avisos,
    this.isAdmin = false,
    this.onRefresh,
    this.naoLidos = 0,
    this.onAvisosAbertos,
  });

  static const _cores = {
    'alerta': Colors.orange, 'importante': Colors.red, 'bjj_news': Colors.purple,
  };
  static const _icons = {
    'alerta': Icons.warning_amber_outlined, 'importante': Icons.error_outline, 'bjj_news': Icons.newspaper,
  };

  Future<void> _deletar(BuildContext ctx, Aviso a) async {
    final ok = await showDialog<bool>(context: ctx,
      builder: (_) => AlertDialog(content: Text('Remover "${a.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ]));
    if (ok == true) {
      await AvisoRepository().deletar(a.id);
      onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: [
        // Header com botão novo aviso para admin
        if (isAdmin) Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Quadro de Avisos', style: TextStyle(fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvisosScreen()))
                  .then((_) => onRefresh?.call()),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Gerenciar'),
              style: TextButton.styleFrom(foregroundColor: verdeEscuro),
            ),
          ]),
        ),
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
              trailing: isAdmin ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deletar(context, a),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ) : null,
            );
          }),
        if (!isAdmin) ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvisosScreen()))
              .then((_) => onAvisosAbertos?.call()),
          title: Text(
            naoLidos > 0 ? 'Ver todos os avisos ($naoLidos novo(s))' : 'Ver todos os avisos',
            style: const TextStyle(color: verdeEscuro, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: verdeEscuro),
        ),
      ]),
    );
  }
}

class _EventosCard extends StatelessWidget {
  final List<Evento> eventos;
  final bool isAdmin;
  final VoidCallback? onRefresh;
  const _EventosCard({required this.eventos, this.isAdmin = false, this.onRefresh});

  Future<void> _deletar(BuildContext ctx, Evento e) async {
    final ok = await showDialog<bool>(context: ctx,
      builder: (_) => AlertDialog(content: Text('Remover "${e.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ]));
    if (ok == true) {
      await EventoRepository().deletar(e.id);
      onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final proximos = eventos.where((e) => e.data.compareTo(hoje) >= 0).take(3).toList();

    return Card(
      child: Column(children: [
        if (isAdmin) Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Próximos Eventos', style: TextStyle(fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarioScreen()))
                  .then((_) => onRefresh?.call()),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Gerenciar'),
              style: TextButton.styleFrom(foregroundColor: verdeEscuro),
            ),
          ]),
        ),
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
                Text('${formatDataBr(e.data)}${e.horaInicio != null ? ' às ${e.horaInicio}${e.horaFim != null ? '–${e.horaFim}' : ''}' : ''}${e.local != null ? ' · ${e.local}' : ''}',
                    style: const TextStyle(fontSize: 12)),
                if (e.linkUrl != null && e.linkUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(e.linkUrl!);
                      if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Text('🔗 Inscrições / Mais info', style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
                  ),
              ]),
              trailing: isAdmin ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deletar(context, e),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ) : null,
            );
          }),
        if (!isAdmin) ListTile(
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
