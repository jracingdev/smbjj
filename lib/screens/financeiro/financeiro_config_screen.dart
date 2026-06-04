import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/financeiro_config.dart';
import '../../models/regra_financeira.dart';
import '../../repositories/financeiro_config_repository.dart';

class FinanceiroConfigScreen extends StatefulWidget {
  const FinanceiroConfigScreen({super.key});

  @override
  State<FinanceiroConfigScreen> createState() => _FinanceiroConfigScreenState();
}

class _FinanceiroConfigScreenState extends State<FinanceiroConfigScreen> {
  final _repo = FinanceiroConfigRepository();
  final _uuid = const Uuid();
  final _adultoCtrl = TextEditingController();
  final _menorCtrl = TextEditingController();
  final _desc2Ctrl = TextEditingController();
  final _desc3Ctrl = TextEditingController();
  final _paganteCtrl = TextEditingController();
  final _vencCtrl = TextEditingController();
  List<RegraFinanceira> _extras = [];
  bool _loading = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _adultoCtrl.dispose();
    _menorCtrl.dispose();
    _desc2Ctrl.dispose();
    _desc3Ctrl.dispose();
    _paganteCtrl.dispose();
    _vencCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = await _repo.obter();
    _adultoCtrl.text = c.valorAdulto.toStringAsFixed(2);
    _menorCtrl.text = c.valorMenor.toStringAsFixed(2);
    _desc2Ctrl.text = c.desconto2oFamiliarPercent.toStringAsFixed(0);
    _desc3Ctrl.text = c.desconto3oFamiliarPercent.toStringAsFixed(0);
    _paganteCtrl.text = c.descontoMesmoPagantePercent.toStringAsFixed(0);
    _vencCtrl.text = '${c.diaVencimento}';
    _extras = List.from(c.regrasExtras);
    if (mounted) setState(() => _loading = false);
  }

  FinanceiroConfig _montarConfig() {
    final adulto = double.tryParse(_adultoCtrl.text.replaceAll(',', '.')) ?? 110;
    final menor = double.tryParse(_menorCtrl.text.replaceAll(',', '.')) ?? 80;
    final d2 = double.tryParse(_desc2Ctrl.text.replaceAll(',', '.')) ?? 10;
    final d3 = double.tryParse(_desc3Ctrl.text.replaceAll(',', '.')) ?? 15;
    final dp = double.tryParse(_paganteCtrl.text.replaceAll(',', '.')) ?? 5;
    final venc = int.tryParse(_vencCtrl.text) ?? 10;
    return FinanceiroConfig(
      valorAdulto: adulto,
      valorMenor: menor,
      desconto2oFamiliarPercent: d2,
      desconto3oFamiliarPercent: d3,
      descontoMesmoPagantePercent: dp,
      diaVencimento: venc.clamp(1, 28),
      regrasExtras: _extras,
    );
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    await _repo.salvar(_montarConfig());
    if (mounted) {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regras e valores salvos!'), backgroundColor: verdeEscuro),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _dialogRegra([RegraFinanceira? existente]) async {
    final tituloCtrl = TextEditingController(text: existente?.titulo ?? '');
    final valorCtrl = TextEditingController(
      text: existente != null ? existente.valor.toString() : '',
    );
    final descCtrl = TextEditingController(text: existente?.descricao ?? '');
    var tipo = existente?.tipo ?? 'texto';
    var ativa = existente?.ativa ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(existente == null ? 'Nova regra' : 'Editar regra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Nome da regra *'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'texto', child: Text('Informativo (só exibe no painel)')),
                    DropdownMenuItem(value: 'desconto_percent', child: Text('Desconto (%) — referência')),
                    DropdownMenuItem(value: 'valor_mensalidade', child: Text('Valor fixo (R\$) — referência')),
                    DropdownMenuItem(value: 'dia_whatsapp', child: Text('Dia extra — lembrete WhatsApp')),
                  ],
                  onChanged: (v) => setD(() => tipo = v ?? 'texto'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: tipo == 'dia_whatsapp' ? 'Dia do mês (1-28)' : 'Valor / %',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                  maxLines: 2,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativa'),
                  value: ativa,
                  onChanged: (v) => setD(() => ativa = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, tituloCtrl.text.trim().isNotEmpty), child: const Text('OK')),
          ],
        ),
      ),
    );

    if (ok == true) {
      final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
      final regra = RegraFinanceira(
        id: existente?.id ?? _uuid.v4(),
        titulo: tituloCtrl.text.trim(),
        tipo: tipo,
        valor: valor,
        descricao: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        ativa: ativa,
      );
      setState(() {
        if (existente != null) {
          final i = _extras.indexWhere((r) => r.id == existente.id);
          if (i >= 0) _extras[i] = regra;
        } else {
          _extras.add(regra);
        }
      });
    }
    tituloCtrl.dispose();
    valorCtrl.dispose();
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regras de Cobrança'),
        actions: [
          IconButton(
            icon: _salvando
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _salvando || _loading ? null : _salvar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Valores base', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _adultoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Mensalidade adulto (R\$)', prefixText: 'R\$ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _menorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Mensalidade menor de 18 anos (R\$)',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Descontos automáticos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _desc2Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '2º integrante da família (%)', suffixText: '%'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _desc3Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '3º integrante ou mais (%)', suffixText: '%'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _paganteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mesmo CPF pagante — 2+ alunos (%)', suffixText: '%'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _vencCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dia de vencimento',
                    helperText: 'Dias 1 e 5 também disparam lembretes WhatsApp',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bolsistas: até 100% — configure no cadastro/validação de cada aluno.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Regras personalizadas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () => _dialogRegra(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova'),
                    ),
                  ],
                ),
                if (_extras.isEmpty)
                  Text('Nenhuma regra extra. Toque em Nova para criar.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
                else
                  ..._extras.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(r.titulo, style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: r.ativa ? null : TextDecoration.lineThrough,
                          )),
                          subtitle: Text('${r.tipo} · ${r.valorExibicao}${r.descricao != null ? "\n${r.descricao}" : ""}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _dialogRegra(r);
                              if (v == 'del') setState(() => _extras.removeWhere((x) => x.id == r.id));
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(value: 'del', child: Text('Excluir', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar todas as regras'),
                ),
              ],
            ),
    );
  }
}
