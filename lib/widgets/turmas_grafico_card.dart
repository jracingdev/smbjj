import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/turma.dart';

/// Gráfico de barras horizontais — alunos por turma (admin).
class TurmasGraficoCard extends StatelessWidget {
  final List<Turma> turmas;
  final Map<String, int> contagem;

  const TurmasGraficoCard({
    super.key,
    required this.turmas,
    required this.contagem,
  });

  @override
  Widget build(BuildContext context) {
    if (turmas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhuma turma cadastrada.'),
        ),
      );
    }

    final ordenadas = [...turmas]..sort((a, b) => (contagem[b.id] ?? 0).compareTo(contagem[a.id] ?? 0));
    final max = ordenadas.fold<int>(0, (m, t) {
      final c = contagem[t.id] ?? 0;
      return c > m ? c : m;
    });
    final maxBar = max == 0 ? 1 : max;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alunos por turma', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 16),
            ...ordenadas.map((t) {
              final n = contagem[t.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Text('$n', style: const TextStyle(fontWeight: FontWeight.w900, color: verdeEscuro)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: n / maxBar,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: verdeEscuro,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
