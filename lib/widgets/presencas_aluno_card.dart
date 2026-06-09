import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/presenca.dart';
import '../models/turma.dart';
import '../utils/date_utils.dart';
import '../utils/treino_utils.dart';
import '../utils/turma_utils.dart';

class PresencasAlunoCard extends StatelessWidget {
  final List<Presenca> presencas;
  final List<Turma> minhasTurmas;
  final int presencasMesAtual;

  const PresencasAlunoCard({
    super.key,
    required this.presencas,
    required this.minhasTurmas,
    this.presencasMesAtual = 0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mesAno = formatMesAnoPartes(now.month, now.year);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check_outlined, color: verdeEscuro, size: 20),
                SizedBox(width: 8),
                Text('Presença nos treinos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$presencasMesAtual presença(s) em $mesAno',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            if (minhasTurmas.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Próximos treinos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              ...minhasTurmas.map((t) {
                final prox = proximosTreinos(t.diasSemana, quantidade: 3);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(
                        '${formatarHorarioTurma(t.horario)} · ${formatarDiasSemana(t.diasSemana)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (prox.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: prox
                              .map((d) => Chip(
                                    label: Text(
                                      formatDataBr('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        )
                      else
                        Text('Dias da turma a definir pelo professor',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            const Text('Histórico recente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            if (presencas.isEmpty)
              Text('Nenhuma presença registrada ainda.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
            else
              ...presencas.take(8).map((p) {
                final icone = p.presente ? Icons.check_circle : Icons.cancel_outlined;
                final cor = p.presente ? Colors.green : Colors.grey;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(icone, size: 16, color: cor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDataBr(p.dataAula),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        p.presente ? 'Presente' : 'Ausente',
                        style: TextStyle(fontSize: 11, color: cor),
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
