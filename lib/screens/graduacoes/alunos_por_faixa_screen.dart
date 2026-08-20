import 'package:flutter/material.dart';
import '../../models/aluno.dart';
import '../../widgets/aluno_avatar.dart';
import '../../widgets/faixa_badge.dart';
import '../../widgets/historico_graduacoes_section.dart';

/// Lista de alunos ativos de uma faixa (volta com pop para o Início).
class AlunosPorFaixaScreen extends StatelessWidget {
  final String faixa;
  final List<Aluno> alunos;

  const AlunosPorFaixaScreen({
    super.key,
    required this.faixa,
    required this.alunos,
  });

  @override
  Widget build(BuildContext context) {
    final lista = [...alunos]..sort((a, b) {
      final byGrau = b.grau.compareTo(a.grau);
      if (byGrau != 0) return byGrau;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Faixa ${labelFaixa(faixa)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: lista.isEmpty
          ? Center(
              child: Text(
                'Nenhum aluno ativo nesta faixa.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = lista[i];
                return ListTile(
                  leading: AlunoAvatar(fotoUrl: a.fotoUrl, nome: a.nome, radius: 22),
                  title: Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(labelGrau(a.grau), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  trailing: FaixaIlustracao(faixa: a.faixa, grau: a.grau, width: 56, height: 10),
                );
              },
            ),
    );
  }
}
