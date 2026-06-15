import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../repositories/medalha_repository.dart';
import '../repositories/aluno_repository.dart';
import '../repositories/pedido_repository.dart';
import '../utils/aniversario_utils.dart';
import '../core/notifications/app_alert_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;
  int _avisosNaoLidos = 0;
  int _medalhasNovas = 0;
  int _aniversariantesHoje = 0;
  int _pedidosPendentes = 0;
  int get _badgeInicio => _avisosNaoLidos + _medalhasNovas + _aniversariantesHoje;
  int get _badgeLoja => _pedidosPendentes;
  final _alunosKey = GlobalKey<AlunosScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _atualizarAvisosNaoLidos();
      _verificarPedidosAdmin();
    });
  }

  Future<void> _verificarPedidosAdmin() async {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAdmin) return;
    try {
      final pedidos = await PedidoRepository().listar(status: 'pendente');
      final prefs = await SharedPreferences.getInstance();
      final visto = prefs.getInt('pedidos_pendentes_visto') ?? 0;
      final novos = pedidos.length;
      if (mounted) setState(() => _pedidosPendentes = novos > visto ? novos - visto : 0);
      if (novos > visto && mounted) {
        await AppAlertService.alertar(
          context,
          titulo: 'Novo pedido na loja',
          mensagem: '${novos - visto} pedido(s) pendente(s) aguardando.',
          cor: Colors.deepOrange.shade800,
        );
      }
      await prefs.setInt('pedidos_pendentes_visto', novos);
    } catch (_) {}
  }

  Future<void> _atualizarAvisosNaoLidos() async {
    if (!mounted) return;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    if (isAdmin) {
      await _verificarPedidosAdmin();
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      final aluno = auth.alunoVinculado;
      final avisos = await AvisoRepository().listar(apenasAtivos: true);
      final medalhas = await MedalhaRepository().listar();
      final n = await AvisoLidoService().contarNaoLidos(avisos);
      final m = await MedalhaLidoService().contarNovas(medalhas);
      var anivBadge = 0;
      if (aluno != null) {
        final aniversariantes = await carregarAniversariantesTurma(AlunoRepository(), aluno.id);
        if (await AniversarioAvisoService().avisoPendente(aniversariantes.length)) {
          anivBadge = aniversariantes.length;
        }
      }
      if (mounted) {
        final avisosNovos = n > _avisosNaoLidos ? n - _avisosNaoLidos : 0;
        final medalhasNovasDelta = m > _medalhasNovas ? m - _medalhasNovas : 0;
        setState(() {
          _avisosNaoLidos = n;
          _medalhasNovas = m;
          _aniversariantesHoje = anivBadge;
        });
        if (avisosNovos > 0) {
          await AppAlertService.alertar(
            context,
            titulo: 'Novo aviso',
            mensagem: '$avisosNovos aviso(s) na academia.',
          );
        } else if (medalhasNovasDelta > 0) {
          await AppAlertService.alertar(
            context,
            titulo: 'Quadro de medalhas',
            mensagem: 'Há atualização no ranking de medalhas.',
            cor: Colors.amber.shade900,
          );
        } else if (anivBadge > 0 && anivBadge > _aniversariantesHoje) {
          await AppAlertService.alertar(
            context,
            titulo: 'Aniversariante da turma',
            mensagem: 'Colega(s) de turma fazem aniversário hoje!',
            cor: Colors.pink.shade700,
          );
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
      const BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Alunos'),
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
