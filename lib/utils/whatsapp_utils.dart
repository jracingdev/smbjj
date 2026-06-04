import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/aluno.dart';
import 'bjj_utils.dart';

/// Tipo de mensagem de cobrança conforme o dia do mês.
String? tipoCobrancaDoDia(int diaHoje, int diaVencimento, {List<int> diasExtras = const []}) {
  if (diaHoje == 1) return 'aviso1';
  if (diaHoje == 5) return 'aviso5';
  if (diasExtras.contains(diaHoje)) return 'aviso_extra';
  if (diaHoje == diaVencimento) return 'vencimento';
  return null;
}

String labelTipoCobranca(String tipo, int diaVencimento) {
  switch (tipo) {
    case 'aviso1':
      return 'Aviso (Dia 1)';
    case 'aviso5':
      return 'Lembrete (Dia 5)';
    case 'vencimento':
      return 'Vencimento (Dia $diaVencimento)';
    case 'aviso_extra':
      return 'Lembrete extra';
    default:
      return 'Cobrança';
  }
}

String _buildMessage({
  required String tipo,
  required Aluno aluno,
  required int mes,
  required int ano,
  required double valor,
  required int diaVencimento,
}) {
  final mesNome = meses[mes - 1];
  final nome = aluno.nomeResponsavel ?? aluno.nome;
  final valorStr = valor.toStringAsFixed(2);

  switch (tipo) {
    case 'aviso1':
      return 'Olá, $nome! 😊\n\n'
          'Passando para lembrar que a mensalidade de *$mesNome/$ano* da SM BJJ está chegando! 🥋\n\n'
          'O vencimento é dia *$diaVencimento de $mesNome*.\n'
          'Valor: *R\$ $valorStr*\n\n'
          'Qualquer dúvida, estamos à disposição! 💪';

    case 'aviso5':
      final diasRestantes = (diaVencimento - 5).clamp(1, 31);
      return 'Olá, $nome! 👋\n\n'
          'Só um lembrete rápido: a mensalidade de *$mesNome/$ano* vence em *$diasRestantes dias* (dia $diaVencimento).\n\n'
          'Valor: *R\$ $valorStr*\n\n'
          'Evite o atraso e garanta sua continuidade nas aulas! 🥋✨';

    case 'aviso_extra':
      return 'Olá, $nome! 👋\n\n'
          'Lembrete da SM BJJ: mensalidade de *$mesNome/$ano*.\n'
          'Vencimento dia *$diaVencimento*.\n'
          'Valor: *R\$ $valorStr*\n\n'
          'Qualquer dúvida, fale conosco! 🥋';

    case 'vencimento':
      return 'Olá, $nome! ⚠️\n\n'
          'Hoje é o *dia do vencimento* da mensalidade de *$mesNome/$ano* da SM BJJ.\n\n'
          'Valor: *R\$ $valorStr*\n\n'
          '⚠️ *Atenção:* O pagamento após o vencimento resultará na '
          '*perda da promoção naquele mês*.\n\n'
          'Regularize hoje para não perder seus benefícios! 💪🥋';

    default:
      return '';
  }
}

Future<void> abrirWhatsApp(String telefone, String mensagem) async {
  final digits = telefone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) return;
  final numero = digits.startsWith('55') ? digits : '55$digits';
  final url = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

Future<void> enviarCobranca({
  required String tipo,
  required Aluno aluno,
  required int mes,
  required int ano,
  double? valor,
  int diaVencimento = 10,
}) async {
  final telefone = aluno.telefoneResponsavel ?? aluno.telefone;
  if (telefone == null || telefone.isEmpty) return;
  final v = valor ?? getValorMensalidade(aluno.dataNascimento);
  final msg = _buildMessage(
    tipo: tipo,
    aluno: aluno,
    mes: mes,
    ano: ano,
    valor: v,
    diaVencimento: diaVencimento,
  );
  await abrirWhatsApp(telefone, msg);
}

/// Abre WhatsApp em sequência para cada aluno pendente (um por vez — simples e compatível com web).
Future<void> enviarCobrancaLote({
  required BuildContext context,
  required String tipo,
  required int mes,
  required int ano,
  required int diaVencimento,
  required List<({Aluno aluno, double valor})> itens,
}) async {
  final comTelefone = <({Aluno aluno, double valor})>[];
  final semTelefone = <String>[];

  for (final item in itens) {
    final tel = item.aluno.telefoneResponsavel ?? item.aluno.telefone;
    if (tel != null && tel.replaceAll(RegExp(r'\D'), '').length >= 10) {
      comTelefone.add(item);
    } else {
      semTelefone.add(item.aluno.nome);
    }
  }

  if (comTelefone.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum pendente com telefone cadastrado.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  final tipoLabel = labelTipoCobranca(tipo, diaVencimento);
  final okInicio = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Enviar $tipoLabel'),
      content: Text(
        'Será aberto o WhatsApp de ${comTelefone.length} aluno(s), um por vez.\n'
        '${semTelefone.isNotEmpty ? "\nSem telefone (${semTelefone.length}): ${semTelefone.join(", ")}" : ""}\n\n'
        'Após enviar cada mensagem, volte aqui e toque em *Próximo*.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Iniciar')),
      ],
    ),
  );
  if (okInicio != true || !context.mounted) return;

  for (var i = 0; i < comTelefone.length; i++) {
    if (!context.mounted) return;
    final item = comTelefone[i];
    final nome = item.aluno.nome;

    final acao = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('${i + 1} de ${comTelefone.length}'),
        content: Text('Abrir WhatsApp para $nome?\nValor: R\$ ${item.valor.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'parar'), child: const Text('Parar')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'pular'), child: const Text('Pular')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'enviar'),
            child: const Text('Abrir WhatsApp'),
          ),
        ],
      ),
    );

    if (acao == 'parar' || acao == null) break;
    if (acao == 'pular') continue;

    await enviarCobranca(
      tipo: tipo,
      aluno: item.aluno,
      mes: mes,
      ano: ano,
      valor: item.valor,
      diaVencimento: diaVencimento,
    );
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Envio em lote concluído.'), backgroundColor: Colors.green),
    );
  }
}
