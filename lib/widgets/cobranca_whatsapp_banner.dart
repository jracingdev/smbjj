import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/aluno.dart';
import '../models/mensalidade.dart';
import '../utils/whatsapp_utils.dart';

/// Banner na aba Mensalidades: sugere envio automático nos dias 1, 5 e vencimento.
class CobrancaWhatsAppBanner extends StatelessWidget {
  final int mes;
  final int ano;
  final int diaVencimento;
  final List<Mensalidade> mensalidades;
  final List<Aluno> alunos;
  final bool mesAtualSelecionado;

  const CobrancaWhatsAppBanner({
    super.key,
    required this.mes,
    required this.ano,
    required this.diaVencimento,
    required this.mensalidades,
    required this.alunos,
    required this.mesAtualSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final tipo = mesAtualSelecionado && hoje.year == ano && hoje.month == mes
        ? tipoCobrancaDoDia(hoje.day, diaVencimento)
        : null;

    final pendentes = mensalidades.where((m) => m.status != 'pago' && !m.cancelada).toList();
    if (pendentes.isEmpty) return const SizedBox.shrink();

    final itens = <({Aluno aluno, double valor})>[];
    for (final m in pendentes) {
      Aluno aluno;
      try {
        aluno = alunos.firstWhere((a) => a.id == m.alunoId);
      } catch (_) {
        aluno = Aluno(id: m.alunoId, nome: m.alunoNome ?? '?');
      }
      itens.add((aluno: aluno, valor: m.valor));
    }

    return Card(
      color: verdeEscuro.withValues(alpha: 0.08),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.chat, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tipo != null
                        ? 'Hoje: ${labelTipoCobranca(tipo, diaVencimento)}'
                        : 'WhatsApp — ${pendentes.length} pendente(s)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tipo != null
                  ? 'Toque abaixo para enviar a mensagem do dia para todos os pendentes (um WhatsApp por vez).'
                  : 'Envie lembretes em lote ou escolha o tipo de mensagem.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            if (tipo != null)
              ElevatedButton.icon(
                onPressed: () => enviarCobrancaLote(
                  context: context,
                  tipo: tipo,
                  mes: mes,
                  ano: ano,
                  diaVencimento: diaVencimento,
                  itens: itens,
                ),
                icon: const Icon(Icons.send),
                label: Text('Automatizar hoje (${pendentes.length})'),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: () => enviarCobrancaLote(
                    context: context,
                    tipo: 'aviso1',
                    mes: mes,
                    ano: ano,
                    diaVencimento: diaVencimento,
                    itens: itens,
                  ),
                  child: Text('Dia 1 (${pendentes.length})', style: const TextStyle(fontSize: 12)),
                ),
                OutlinedButton(
                  onPressed: () => enviarCobrancaLote(
                    context: context,
                    tipo: 'aviso5',
                    mes: mes,
                    ano: ano,
                    diaVencimento: diaVencimento,
                    itens: itens,
                  ),
                  child: Text('Dia 5', style: const TextStyle(fontSize: 12)),
                ),
                OutlinedButton(
                  onPressed: () => enviarCobrancaLote(
                    context: context,
                    tipo: 'vencimento',
                    mes: mes,
                    ano: ano,
                    diaVencimento: diaVencimento,
                    itens: itens,
                  ),
                  child: Text('Venc. $diaVencimento', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
