import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth/auth_provider.dart';
import '../core/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'alunos/alunos_screen.dart';
import 'financeiro/financeiro_screen.dart';
import 'loja/loja_screen.dart';
import 'perfil/perfil_screen.dart';
import '../../widgets/cadastro_gate.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;
  final _alunosKey = GlobalKey<AlunosScreenState>();

  void _abrirAlunosPendentes() {
    setState(() => _tabIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alunosKey.currentState?.filtrarPendentes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final adminTabs = [
      DashboardScreen(onValidarPendentes: _abrirAlunosPendentes),
      AlunosScreen(key: _alunosKey),
      const FinanceiroScreen(),
      const LojaScreen(),
      const PerfilScreen(),
    ];

    final alunoTabs = [
      const DashboardScreen(),
      const LojaScreen(),
      const PerfilScreen(),
    ];

    final tabs = isAdmin ? adminTabs : alunoTabs;

    final adminNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Início'),
      const BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Alunos'),
      const BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Financeiro'),
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Loja'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
    ];

    final alunoNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
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
              child: IndexedStack(
                index: _tabIndex.clamp(0, tabs.length - 1),
                children: tabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex.clamp(0, tabs.length - 1),
        onTap: (i) => setState(() => _tabIndex = i),
        items: isAdmin ? adminNavItems : alunoNavItems,
        selectedItemColor: verdeEscuro,
      ),
    );
  }
}
