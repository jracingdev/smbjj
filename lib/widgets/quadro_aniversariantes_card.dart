import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/aluno.dart';
import '../utils/aniversario_utils.dart';
import 'aluno_avatar.dart';

/// Quadro automático de aniversariantes do mês.
class QuadroAniversariantesCard extends StatelessWidget {
  final List<Aluno> aniversariantes;
  final String? alunoAtualId;
  final VoidCallback? onMarcarVisto;

  const QuadroAniversariantesCard({
    super.key,
    required this.aniversariantes,
    this.alunoAtualId,
    this.onMarcarVisto,
  });

  @override
  Widget build(BuildContext context) {
    final mesLabel = _nomeMes(DateTime.now().month);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, color: Colors.pink.shade700, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aniversariantes de $mesLabel',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                if (onMarcarVisto != null)
                  TextButton(
                    onPressed: onMarcarVisto,
                    child: const Text('Ok', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          if (aniversariantes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Text(
                'Nenhum aniversariante cadastrado neste mês.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else
            ...aniversariantes.map((a) {
              final dia = diaAniversario(a.dataNascimento) ?? 0;
              final hoje = aniversarioHoje(a.dataNascimento);
              final souEu = a.id == alunoAtualId;
              return ListTile(
                dense: true,
                leading: AlunoAvatar(fotoUrl: a.fotoUrl, nome: a.nome, radius: 18),
                title: Text(
                  a.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: hoje ? Colors.pink.shade900 : null,
                  ),
                ),
                subtitle: Text(
                  hoje
                      ? (souEu ? 'É o seu dia! 🎉' : 'Aniversário hoje!')
                      : 'Dia ${dia.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: hoje ? Colors.pink.shade700 : Colors.grey.shade600,
                    fontWeight: hoje ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: hoje
                    ? Icon(Icons.celebration, color: Colors.pink.shade600)
                    : Text(
                        dia.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: verdeEscuro,
                          fontSize: 16,
                        ),
                      ),
              );
            }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  static String _nomeMes(int mes) {
    const nomes = [
      '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    if (mes < 1 || mes > 12) return '';
    return nomes[mes];
  }
}
