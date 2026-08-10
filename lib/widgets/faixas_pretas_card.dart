import 'package:flutter/material.dart';
import '../models/graduacao.dart';
import '../utils/date_utils.dart';
import '../widgets/faixa_badge.dart';
import '../widgets/historico_graduacoes_section.dart';
import '../screens/graduacoes/faixas_pretas_screen.dart';

/// Prévia do quadro de faixas-pretas formadas pela academia.
class FaixasPretasCard extends StatelessWidget {
  final List<Graduacao> pretas;
  final bool isAdmin;

  const FaixasPretasCard({
    super.key,
    required this.pretas,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final amostra = pretas.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade700, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.military_tech, color: Colors.amber.shade600, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Faixas-pretas SM BJJ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FaixasPretasScreen(isAdmin: isAdmin)),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.amber.shade300),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              Text(
                'Formados na casa',
                style: TextStyle(color: Colors.amber.shade200, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (amostra.isEmpty)
                Text(
                  'Nenhuma faixa-preta formada cadastrada ainda.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                )
              else
                ...amostra.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          FaixaIlustracao(faixa: 'preta', grau: g.grau, width: 56, height: 10),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.alunoNome,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${formatDataBr(g.dataGraduacao)} · ${labelGrau(g.grau)}',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}
