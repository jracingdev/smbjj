import 'package:url_launcher/url_launcher.dart';
import '../models/aluno.dart';
import 'bjj_utils.dart';

String _buildMessage(String tipo, Aluno aluno, int mes, int ano) {
  final mesNome = meses[mes - 1];
  final valor = getValorMensalidade(aluno.dataNascimento);
  final nome = aluno.nomeResponsavel ?? aluno.nome;

  switch (tipo) {
    case 'aviso1':
      return 'Olá, $nome! 😊\n\n'
          'Passando para lembrar que a mensalidade de *$mesNome/$ano* da SM BJJ está chegando! 🥋\n\n'
          'O vencimento é dia *10 de $mesNome*.\n'
          'Valor: *R\$ ${valor.toStringAsFixed(2)}*\n\n'
          'Qualquer dúvida, estamos à disposição! 💪';

    case 'aviso5':
      return 'Olá, $nome! 👋\n\n'
          'Só um lembrete rápido: a mensalidade de *$mesNome/$ano* vence em *5 dias* (dia 10).\n\n'
          'Valor: *R\$ ${valor.toStringAsFixed(2)}*\n\n'
          'Evite o atraso e garanta sua continuidade nas aulas! 🥋✨';

    case 'vencimento':
      return 'Olá, $nome! ⚠️\n\n'
          'Hoje é o *dia do vencimento* da mensalidade de *$mesNome/$ano* da SM BJJ.\n\n'
          'Valor: *R\$ ${valor.toStringAsFixed(2)}*\n\n'
          '⚠️ *Atenção:* O pagamento após o vencimento resultará na '
          '*perda da promoção naquele mês*.\n\n'
          'Regularize hoje para não perder seus benefícios! 💪🥋';

    default:
      return '';
  }
}

Future<void> abrirWhatsApp(String telefone, String mensagem) async {
  final numero = telefone.replaceAll(RegExp(r'\D'), '');
  final url = Uri.parse('https://wa.me/55$numero?text=${Uri.encodeComponent(mensagem)}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

Future<void> enviarCobranca({
  required String tipo,
  required Aluno aluno,
  required int mes,
  required int ano,
}) async {
  final telefone = aluno.telefoneResponsavel ?? aluno.telefone;
  if (telefone == null || telefone.isEmpty) return;
  final msg = _buildMessage(tipo, aluno, mes, ano);
  await abrirWhatsApp(telefone, msg);
}
