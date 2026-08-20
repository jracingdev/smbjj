import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/aluno.dart';
import '../screens/graduacoes/alunos_por_faixa_screen.dart';
import '../utils/bjj_utils.dart';
import '../widgets/faixa_badge.dart';
import '../widgets/historico_graduacoes_section.dart';

/// Quadro com todas as faixas e total de alunos ativos em cada uma.
class QuadroFaixasCard extends StatelessWidget {
  final List<Aluno> alunos;
  final bool apenasVisiveis;

  const QuadroFaixasCard({
    super.key,
    required this.alunos,
    this.apenasVisiveis = false,
  });

  Map<String, int> get _contagem {
    final map = {for (final f in faixas) f: 0};
    for (final a in alunos.where((a) => a.ativo)) {
      map[a.faixa] = (map[a.faixa] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final contagem = _contagem;
    final total = contagem.values.fold(0, (s, n) => s + n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (apenasVisiveis)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Contagem entre você e colegas de turma (visíveis pelo app).',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        Text(
          total == 0
              ? 'Nenhum aluno ativo no momento.'
              : '$total aluno${total == 1 ? '' : 's'} ativo${total == 1 ? '' : 's'} · toque numa faixa para ver a lista',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        ...faixas.map((faixa) {
          final qtd = contagem[faixa] ?? 0;
          final cor = getFaixaColor(faixa);
          final borda = faixa == 'branca' ? Colors.grey.shade400 : cor.withValues(alpha: 0.55);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlunosPorFaixaScreen(
                        faixa: faixa,
                        alunos: alunos.where((a) => a.ativo && a.faixa == faixa).toList(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borda),
                    color: cor.withValues(alpha: faixa == 'branca' ? 0.08 : 0.06),
                  ),
                  child: Row(
                    children: [
                      FaixaIlustracao(faixa: faixa, grau: 0, width: 52, height: 10),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          labelFaixa(faixa),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      Text(
                        '$qtd',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: faixa == 'preta' || faixa == 'azul' || faixa == 'roxa' || faixa == 'marrom'
                              ? cor
                              : verdeEscuro,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        qtd == 1 ? 'aluno' : 'alunos',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
