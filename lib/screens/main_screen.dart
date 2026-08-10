import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/auth/auth_provider.dart';
import '../core/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'alunos/alunos_screen.dart';
import 'financeiro/financeiro_screen.dart';
import 'loja/loja_screen.dart';
import 'perfil/perfil_screen.dart';
import 'turma/turma_aluno_screen.dart';
import '../../widgets/cadastro_gate.dart';
import '../repositories/aviso_repository.dart';
import '../core/avisos/aviso_lido_service.dart';
import '../core/medalhas/medalha_lido_service.dart';
import '../core/aniversario/aniversario_aviso_service.dart';
import '../core/aniversario/aniversario_mes_aviso_service.dart';
import '../core/eventos/evento_lido_service.dart';
import '../core/financeiro/vencimento_aviso_service.dart';
import '../repositories/medalha_repository.dart';
import '../repositories/aluno_repository.dart';
import '../repositories/pedido_repository.dart';
import '../repositories/evento_repository.dart';
import '../repositories/mensalidade_repository.dart';
import '../repositories/financeiro_config_repository.dart';
import '../utils/aniversario_utils.dart';
import '../utils/whatsapp_utils.dart';
import '../core/notifications/app_alert_service.dart';
import '../core/notifications/local_notification_service.dart';
import '../widgets/aniversario_celebration.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _tabIndex = 0;
  int _avisosNaoLidos = 0;
  int _medalhasNovas = 0;
  int _eventosNovos = 0;
  int _aniversariantesHoje = 0;
  int _aniversariantesMes = 0;
  int _pedidosPendentes = 0;
  int _cadastrosPendentes = 0;
  int get _badgeInicio =>
      _avisosNaoLidos + _medalhasNovas + _eventosNovos + _aniversariantesHoje + _aniversariantesMes;
  int get _badgeLoja => _pedidosPendentes;
  final _alunosKey = GlobalKey<AlunosScreenState>();
  bool _celebracaoMostrada = false;
  Timer? _adminPollTimer;
  bool _adminCheckEmAndamento = false;

  bool get _appEmForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
      WidgetsBinding.instance.lifecycleState == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _atualizarAvisosNaoLidos();
      _iniciarPollingAdmin();
    });
  }

  @override
  void dispose() {
    _adminPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _atualizarAvisosNaoLidos();
      _iniciarPollingAdmin();
    } else if (state == AppLifecycleState.paused) {
      // Mantém polling leve em background enquanto o processo viver.
    }
  }

  void _iniciarPollingAdmin() {
    _adminPollTimer?.cancel();
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAdmin) return;
    _adminPollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      if (!context.read<AuthProvider>().isAdmin) return;
      _checarNovidadesAdmin();
    });
  }

  Future<void> _checarNovidadesAdmin() async {
    if (!mounted || _adminCheckEmAndamento) return;
    if (!context.read<AuthProvider>().isAdmin) return;
    _adminCheckEmAndamento = true;
    try {
      await _verificarCadastrosAdmin();
      await _verificarPedidosAdmin();
    } finally {
      _adminCheckEmAndamento = false;
    }
  }

  Future<void> _alertarAdmin({
    required String titulo,
    required String mensagem,
    required Color cor,
    required int notifId,
  }) async {
    if (!mounted) return;
    if (_appEmForeground) {
      // Foreground: banner com logo + som in-app.
      await AppAlertService.alertar(
        context,
        titulo: titulo,
        mensagem: mensagem,
        cor: cor,
      );
    } else {
      // Background: notificação do sistema (canal com som + ícone).
      await LocalNotificationService.instance.mostrar(
        titulo: titulo,
        mensagem: mensagem,
        id: notifId,
      );
    }
  }

  Future<void> _verificarCadastrosAdmin() async {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAdmin) return;
    try {
      final pendentes = await AlunoRepository().pendentesValidacao();
      final prefs = await SharedPreferences.getInstance();
      final idsAtuais = pendentes.map((a) => a.id).toList();
      if (mounted) setState(() => _cadastrosPendentes = pendentes.length);

      // Migra contador antigo → lista de IDs (evita perder alerta quando a contagem não sobe).
      if (!prefs.containsKey('cadastros_ids_vistos')) {
        await prefs.setStringList('cadastros_ids_vistos', idsAtuais.take(200).toList());
        await prefs.remove('cadastros_pendentes_visto');
        return;
      }

      final vistos = (prefs.getStringList('cadastros_ids_vistos') ?? []).toSet();
      final novos = pendentes.where((a) => !vistos.contains(a.id)).toList();
      if (novos.isNotEmpty && mounted) {
        final nomes = novos.take(3).map((a) => a.nome.split(' ').first).join(', ');
        await _alertarAdmin(
          titulo: 'Novo cadastro de aluno',
          mensagem: novos.length == 1
              ? '$nomes aguarda validação.'
              : '${novos.length} cadastro(s) aguardando: $nomes${novos.length > 3 ? "…" : ""}',
          cor: Colors.amber.shade900,
          notifId: 9101,
        );
      }
      await prefs.setStringList('cadastros_ids_vistos', idsAtuais.take(200).toList());
    } catch (_) {}
  }

  Future<void> _verificarPedidosAdmin() async {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAdmin) return;
    try {
      final pedidos = await PedidoRepository().listar();
      final prefs = await SharedPreferences.getInstance();
      final pendentes = pedidos.where((p) => p.status == 'pendente').length;
      if (mounted) setState(() => _pedidosPendentes = pendentes);

      if (!prefs.containsKey('pedidos_ids_vistos')) {
        await prefs.setStringList(
          'pedidos_ids_vistos',
          pedidos.map((p) => p.id).take(200).toList(),
        );
        return;
      }

      final vistos = (prefs.getStringList('pedidos_ids_vistos') ?? []).toSet();
      final novos = pedidos.where((p) => !vistos.contains(p.id)).toList();
      if (novos.isNotEmpty && mounted) {
        final primeiro = novos.first;
        await _alertarAdmin(
          titulo: 'Nova venda na loja',
          mensagem: novos.length == 1
              ? '${primeiro.alunoNome} pediu ${primeiro.produtoNome}.'
              : '${novos.length} nova(s) venda(s). Ex.: ${primeiro.produtoNome}',
          cor: Colors.deepOrange.shade800,
          notifId: 9102,
        );
      }
      await prefs.setStringList(
        'pedidos_ids_vistos',
        pedidos.map((p) => p.id).take(200).toList(),
      );
    } catch (_) {}
  }

  Future<void> _atualizarAvisosNaoLidos() async {
    if (!mounted) return;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    if (isAdmin) {
      await _checarNovidadesAdmin();
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      final aluno = auth.alunoVinculado;
      final avisos = await AvisoRepository().listar(apenasAtivos: true);
      final medalhas = await MedalhaRepository().listar();
      final eventos = await EventoRepository().listar();
      final n = await AvisoLidoService().contarNaoLidos(avisos);
      final m = await MedalhaLidoService().contarNovas(medalhas);
      final e = await EventoLidoService().contarNaoLidos(eventos);

      var anivBadge = 0;
      var anivMesBadge = 0;
      if (aluno != null) {
        final aniversariantes = await carregarAniversariantesTurma(AlunoRepository(), aluno.id);
        if (await AniversarioAvisoService().avisoPendente(aniversariantes.length)) {
          anivBadge = aniversariantes.length;
        }
        final colegas = await AlunoRepository().listarColegasDeTurmas(aluno.id);
        final doMes = aniversariantesDoMes(alunos: [aluno, ...colegas]);
        if (await AniversarioMesAvisoService().avisoPendente(doMes.length)) {
          anivMesBadge = doMes.isEmpty ? 0 : 1;
        }
      }

      // Vencimento in-app para o aluno (todos recebem no próprio aparelho no dia).
      if (aluno != null && mounted) {
        try {
          final cfg = await FinanceiroConfigRepository().obter();
          final mens = await MensalidadeRepository().porAluno(aluno.id);
          final vencSvc = VencimentoAvisoService();
          final tipo = vencSvc.tipoPendenteHoje(
            minhasMensalidades: mens,
            diaVencimento: cfg.diaVencimento,
            diasExtras: cfg.diasWhatsAppExtras,
          );
          if (tipo != null && await vencSvc.avisoPendente(tipo) && mounted) {
            await AppAlertService.alertar(
              context,
              titulo: labelTipoCobranca(tipo, cfg.diaVencimento),
              mensagem: 'Sua mensalidade está pendente. Regularize para manter os benefícios.',
              cor: Colors.red.shade800,
            );
            await vencSvc.marcarVisto(tipo);
          }
        } catch (_) {}
      }

      if (mounted) {
        final avisosAntes = _avisosNaoLidos;
        final medalhasAntes = _medalhasNovas;
        final eventosAntes = _eventosNovos;
        final anivAntes = _aniversariantesHoje;
        setState(() {
          _avisosNaoLidos = n;
          _medalhasNovas = m;
          _eventosNovos = e;
          _aniversariantesHoje = anivBadge;
          _aniversariantesMes = anivMesBadge;
        });
        if (n > avisosAntes) {
          await AppAlertService.alertar(
            context,
            titulo: 'Novo aviso',
            mensagem: '${n - avisosAntes} aviso(s) na academia.',
          );
        } else if (m > medalhasAntes) {
          await AppAlertService.alertar(
            context,
            titulo: 'Quadro de medalhas',
            mensagem: 'Há atualização no ranking de medalhas.',
            cor: Colors.amber.shade900,
          );
        } else if (e > eventosAntes) {
          await AppAlertService.alertar(
            context,
            titulo: 'Novo evento / campeonato',
            mensagem: '${e - eventosAntes} evento(s) novo(s) no calendário.',
            cor: Colors.indigo.shade800,
          );
        } else if (anivBadge > 0 && anivBadge != anivAntes) {
          await AppAlertService.alertar(
            context,
            titulo: 'Aniversariante da turma',
            mensagem: 'Colega(s) de turma fazem aniversário hoje!',
            cor: Colors.pink.shade700,
          );
        } else if (anivMesBadge > 0) {
          await AppAlertService.alertar(
            context,
            titulo: 'Aniversariantes do mês',
            mensagem: 'Confira o quadro de aniversariantes deste mês.',
            cor: Colors.pink.shade800,
          );
        }

        // Fogos/confetes na tela do aniversariante.
        if (!_celebracaoMostrada &&
            aluno != null &&
            aniversarioHoje(aluno.dataNascimento) &&
            mounted) {
          final anivSvc = AniversarioAvisoService();
          if (await anivSvc.celebracaoPendente() && mounted) {
            _celebracaoMostrada = true;
            await mostrarCelebracaoAniversario(context, aluno.nome);
            await anivSvc.marcarCelebracaoVisto();
          }
        }
      }
    } catch (_) {}
  }

  void _abrirAlunosPendentes() {
    setState(() => _tabIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alunosKey.currentState?.filtrarPendentes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final lojaIndex = isAdmin ? 3 : 2;

    final adminNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Início'),
      BottomNavigationBarItem(
        icon: _cadastrosPendentes > 0
            ? Badge(label: Text('$_cadastrosPendentes'), child: const Icon(Icons.people_outline))
            : const Icon(Icons.people_outline),
        activeIcon: _cadastrosPendentes > 0
            ? Badge(label: Text('$_cadastrosPendentes'), child: const Icon(Icons.people))
            : const Icon(Icons.people),
        label: 'Alunos',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Financeiro'),
      BottomNavigationBarItem(
        icon: _badgeLoja > 0
            ? Badge(label: Text('$_badgeLoja'), child: const Icon(Icons.shopping_bag_outlined))
            : const Icon(Icons.shopping_bag_outlined),
        activeIcon: _badgeLoja > 0
            ? Badge(label: Text('$_badgeLoja'), child: const Icon(Icons.shopping_bag))
            : const Icon(Icons.shopping_bag),
        label: 'Loja',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
    ];

    final alunoNavItems = [
      BottomNavigationBarItem(
        icon: _badgeInicio > 0
            ? Badge(
                label: Text('$_badgeInicio'),
                child: const Icon(Icons.home_outlined),
              )
            : const Icon(Icons.home_outlined),
        activeIcon: _badgeInicio > 0
            ? Badge(
                label: Text('$_badgeInicio'),
                child: const Icon(Icons.home),
              )
            : const Icon(Icons.home),
        label: 'Início',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Turma'),
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Loja'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
    ];

    return Scaffold(
      extendBody: false,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const BannerAguardandoValidacao(),
            Expanded(
              child: _corpoAba(isAdmin, lojaIndex),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
        currentIndex: _tabIndex.clamp(0, isAdmin ? 4 : 3),
        onTap: (i) {
          setState(() => _tabIndex = i);
          if (!isAdmin && i == 0) {
            _atualizarAvisosNaoLidos();
          } else if (isAdmin && i == 1) {
            setState(() => _cadastrosPendentes = 0);
          } else if (isAdmin && i == 3) {
            setState(() => _pedidosPendentes = 0);
          }
        },
        items: isAdmin ? adminNavItems : alunoNavItems,
        selectedItemColor: verdeEscuro,
      ),
      ),
    );
  }

  /// Monta só a aba ativa (evita carregar Loja/Dashboard/Alunos ao mesmo tempo).
  Widget _corpoAba(bool isAdmin, int lojaIndex) {
    final i = _tabIndex.clamp(0, isAdmin ? 4 : 3);
    if (isAdmin) {
      switch (i) {
        case 0:
          return DashboardScreen(onValidarPendentes: _abrirAlunosPendentes);
        case 1:
          return AlunosScreen(key: _alunosKey);
        case 2:
          return const FinanceiroScreen();
        case 3:
          return LojaScreen(tabAtiva: i == lojaIndex);
        case 4:
          return const PerfilScreen();
      }
    } else {
      switch (i) {
        case 0:
          return DashboardScreen(onAvisosLidos: _atualizarAvisosNaoLidos);
        case 1:
          return const TurmaAlunoScreen();
        case 2:
          return LojaScreen(tabAtiva: i == lojaIndex);
        case 3:
          return const PerfilScreen();
      }
    }
    return const SizedBox.shrink();
  }
}
