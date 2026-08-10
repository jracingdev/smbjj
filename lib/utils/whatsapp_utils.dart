import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/aluno.dart';
import 'bjj_utils.dart';
import 'date_utils.dart';

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
  final mesAno = formatMesAnoPartes(mes, ano);
  final nome = aluno.nomeResponsavel ?? aluno.nome;
  final valorStr = valor.toStringAsFixed(2);

  switch (tipo) {
    case 'aviso1':
      return 'Olá, $nome! 😊\n\n'
          'Passando para lembrar que a mensalidade de *$mesAno* da SM BJJ está chegando! 🥋\n\n'
          'O vencimento é dia *$diaVencimento*.\n'
          'Valor: *R\$ $valorStr*\n\n'
          'Qualquer dúvida, estamos à disposição! 💪';

    case 'aviso5':
      final diasRestantes = (diaVencimento - 5).clamp(1, 31);
      return 'Olá, $nome! 👋\n\n'
          'Só um lembrete rápido: a mensalidade de *$mesAno* vence em *$diasRestantes dias* (dia $diaVencimento).\n\n'
          'Valor: *R\$ $valorStr*\n\n'
          'Evite o atraso e garanta sua continuidade nas aulas! 🥋✨';

    case 'aviso_extra':
      return 'Olá, $nome! 👋\n\n'
          'Lembrete da SM BJJ: mensalidade de *$mesAno*.\n'
          'Vencimento dia *$diaVencimento*.\n'
          'Valor: *R\$ $valorStr*\n\n'
          'Qualquer dúvida, fale conosco! 🥋';

    case 'vencimento':
      return 'Olá, $nome! ⚠️\n\n'
          'Hoje é o *dia do vencimento* da mensalidade de *$mesAno* da SM BJJ.\n\n'
          'Valor: *R\$ $valorStr*\n\n'
          '⚠️ *Atenção:* O pagamento após o vencimento resultará na '
          '*perda da promoção naquele mês*.\n\n'
          'Regularize hoje para não perder seus benefícios! 💪🥋';

    default:
      return '';
  }
}

Future<bool> abrirWhatsApp(String telefone, String mensagem) async {
  final digits = telefone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) return false;
  final numero = digits.startsWith('55') ? digits : '55$digits';
  final url = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}');
  try {
    // canLaunchUrl falha em alguns Androids mesmo com WhatsApp instalado.
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
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

/// Envia cobrança em lote: uma confirmação e fila guiada por retorno do WhatsApp
/// (sem diálogo de confirmação por aluno).
///
/// Abrir vários `wa.me` em loop rápido falha no Android (app vai para background
/// e os launches seguintes são perdidos). Aqui abrimos um por vez e avançamos
/// automaticamente quando o usuário volta ao app.
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
        'Serão abertas ${comTelefone.length} conversas do WhatsApp, uma após a outra.\n'
        'Confirme só uma vez aqui; no WhatsApp toque em Enviar e volte — o próximo abre sozinho.\n'
        '${semTelefone.isNotEmpty ? "\nSem telefone (${semTelefone.length}): ${semTelefone.take(8).join(", ")}${semTelefone.length > 8 ? "…" : ""}" : ""}',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar a todos')),
      ],
    ),
  );
  if (okInicio != true || !context.mounted) return;

  final enviados = await Navigator.of(context).push<int>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _CobrancaLotePage(
        tipo: tipo,
        mes: mes,
        ano: ano,
        diaVencimento: diaVencimento,
        itens: comTelefone,
        tipoLabel: tipoLabel,
      ),
    ),
  );

  if (context.mounted && enviados != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cobrança disparada para $enviados aluno(s).'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _CobrancaLotePage extends StatefulWidget {
  final String tipo;
  final String tipoLabel;
  final int mes;
  final int ano;
  final int diaVencimento;
  final List<({Aluno aluno, double valor})> itens;

  const _CobrancaLotePage({
    required this.tipo,
    required this.tipoLabel,
    required this.mes,
    required this.ano,
    required this.diaVencimento,
    required this.itens,
  });

  @override
  State<_CobrancaLotePage> createState() => _CobrancaLotePageState();
}

class _CobrancaLotePageState extends State<_CobrancaLotePage> with WidgetsBindingObserver {
  int _indice = 0;
  int _abertos = 0;
  bool _aguardandoRetorno = false;
  bool _finalizado = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirAtual());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _aguardandoRetorno && !_finalizado) {
      _aguardandoRetorno = false;
      // Pequena pausa para o SO estabilizar antes do próximo launch.
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted || _finalizado) return;
        _avancar();
      });
    }
  }

  ({Aluno aluno, double valor}) get _atual => widget.itens[_indice];

  Future<void> _abrirAtual() async {
    if (_finalizado || !mounted) return;
    final item = _atual;
    final tel = item.aluno.telefoneResponsavel ?? item.aluno.telefone ?? '';
    final msg = _buildMessage(
      tipo: widget.tipo,
      aluno: item.aluno,
      mes: widget.mes,
      ano: widget.ano,
      valor: item.valor,
      diaVencimento: widget.diaVencimento,
    );

    setState(() {
      _erro = null;
      _aguardandoRetorno = true;
    });

    final ok = await abrirWhatsApp(tel, msg);
    if (!mounted) return;
    if (ok) {
      _abertos++;
      setState(() {});
    } else {
      setState(() {
        _erro = 'Não foi possível abrir o WhatsApp para ${item.aluno.nome}.';
        _aguardandoRetorno = false;
      });
    }
  }

  void _avancar() {
    if (_finalizado) return;
    if (_indice >= widget.itens.length - 1) {
      _concluir();
      return;
    }
    setState(() => _indice++);
    _abrirAtual();
  }

  void _pular() {
    if (_finalizado) return;
    _aguardandoRetorno = false;
    _avancar();
  }

  void _concluir() {
    if (_finalizado) return;
    _finalizado = true;
    Navigator.of(context).pop(_abertos);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.itens.length;
    final aluno = _atual.aluno;
    final progresso = (_indice + 1).clamp(1, total);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _concluir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tipoLabel),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _concluir,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Progresso $progresso de $total',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progresso / total),
              const SizedBox(height: 24),
              Text(
                aluno.nome,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${_atual.valor.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                _aguardandoRetorno
                    ? 'WhatsApp aberto. Envie a mensagem e volte ao app — o próximo abre automaticamente.'
                    : (_erro ?? 'Pronto para abrir o WhatsApp.'),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.35),
              ),
              const Spacer(),
              if (_erro != null)
                ElevatedButton.icon(
                  onPressed: _abrirAtual,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar de novo'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pular,
                icon: const Icon(Icons.skip_next),
                label: const Text('Pular este aluno'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _concluir,
                child: const Text('Encerrar lote'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
