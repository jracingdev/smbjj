import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/aluno.dart';
import '../models/mensalidade.dart';
import '../utils/whatsapp_utils.dart';

/// Banner compacto na aba Mensalidades — cobrança WhatsApp dias 1, 5 e vencimento.
class CobrancaWhatsAppBanner extends StatelessWidget {
  final int mes;
  final int ano;
  final int diaVencimento;
  final List<int> diasWhatsAppExtras;
  final List<Mensalidade> mensalidades;
  final List<Aluno> alunos;
  final bool mesAtualSelecionado;

  const CobrancaWhatsAppBanner({
    super.key,
    required this.mes,
    required this.ano,
    required this.diaVencimento,
    this.diasWhatsAppExtras = const [],
    required this.mensalidades,
    required this.alunos,
    required this.mesAtualSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final tipo = mesAtualSelecionado && hoje.year == ano && hoje.month == mes
        ? tipoCobrancaDoDia(hoje.day, diaVencimento, diasExtras: diasWhatsAppExtras)
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

    final titulo = tipo != null
        ? 'Hoje: ${labelTipoCobranca(tipo, diaVencimento)} (${pendentes.length})'
        : 'Cobrança WhatsApp (${pendentes.length} pend.)';

    return Card(
      color: verdeEscuro.withValues(alpha: 0.06),
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: tipo != null,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          leading: Icon(Icons.chat, color: Colors.green.shade700, size: 22),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          subtitle: tipo != null
              ? const Text('Toque para expandir e enviar lembretes', style: TextStyle(fontSize: 11))
              : null,
          children: [
            if (tipo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: () => enviarCobrancaLote(
                    context: context,
                    tipo: tipo,
                    mes: mes,
                    ano: ano,
                    diaVencimento: diaVencimento,
                    itens: itens,
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  label: Text('Automatizar hoje (${pendentes.length})'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                ),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: () => enviarCobrancaLote(context: context, tipo: 'aviso1', mes: mes, ano: ano, diaVencimento: diaVencimento, itens: itens),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: Text('Dia 1', style: const TextStyle(fontSize: 11)),
                ),
                OutlinedButton(
                  onPressed: () => enviarCobrancaLote(context: context, tipo: 'aviso5', mes: mes, ano: ano, diaVencimento: diaVencimento, itens: itens),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Dia 5', style: TextStyle(fontSize: 11)),
                ),
                OutlinedButton(
                  onPressed: () => enviarCobrancaLote(context: context, tipo: 'vencimento', mes: mes, ano: ano, diaVencimento: diaVencimento, itens: itens),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: Text('Venc. $diaVencimento', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
