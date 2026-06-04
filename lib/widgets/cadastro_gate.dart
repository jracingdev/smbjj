import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth/auth_provider.dart';
import '../core/theme.dart';
import '../screens/alunos/meu_cadastro_screen.dart';
import '../screens/main_screen.dart';

/// Após login, aluno sem cadastro na academia vê o formulário obrigatório.
class CadastroGate extends StatelessWidget {
  const CadastroGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.carregando || auth.carregandoAluno) {
          return const Scaffold(
            backgroundColor: verdeEscuro,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Carregando seu perfil...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (auth.isAdmin) return const MainScreen();

        if (auth.precisaCompletarCadastro) {
          return const MeuCadastroScreen();
        }

        return const MainScreen();
      },
    );
  }
}

/// Banner exibido enquanto o cadastro aguarda validação do professor.
class BannerAguardandoValidacao extends StatelessWidget {
  const BannerAguardandoValidacao({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.aguardandoValidacao) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top, color: Colors.amber.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cadastro enviado',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.amber.shade900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'O professor irá validar seus dados e definir sua turma.',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900.withValues(alpha: 0.85)),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MeuCadastroScreen(editar: true)),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: verdeEscuro,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Revisar meu cadastro'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
