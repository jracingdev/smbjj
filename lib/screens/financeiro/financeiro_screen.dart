import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/financeiro/calculo_mensalidade.dart';
import '../../core/financeiro/projecao_financeira.dart';
import '../../core/theme.dart';
import '../../core/mp_service.dart';
import '../../models/aluno.dart';
import '../../models/financeiro_config.dart';
import '../../models/mensalidade.dart';
import '../../models/turma.dart';
import '../../repositories/aluno_repository.dart';
import '../../repositories/financeiro_config_repository.dart';
import '../../repositories/mensalidade_repository.dart';
import '../../repositories/turma_repository.dart';
import '../../utils/bjj_utils.dart';
import '../../utils/whatsapp_utils.dart';
import '../../widgets/cobranca_whatsapp_banner.dart';
import 'financeiro_config_screen.dart';
import 'mp_config_screen.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});
  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> with SingleTickerProviderStateMixin {
  final _mensRepo = MensalidadeRepository();
  final _alunoRepo = AlunoRepository();
  final _configRepo = FinanceiroConfigRepository();
  final _turmaRepo = TurmaRepository();
  late final TabController _tabs = TabController(length: 3, vsync: this);

  List<Mensalidade> _mensalidades = [];
  List<Mensalidade> _mensalidadesAno = [];
  List<Aluno> _alunos = [];
  List<Turma> _turmas = [];
  Map<String, List<String>> _alunoIdsPorTurma = {};
  FinanceiroConfig _config = const FinanceiroConfig();
  bool _loading = true;
  int _mes = DateTime.now().month;
  int _ano = DateTime.now().year;
  bool _mpConfigurado = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = await MercadoPagoService.instance.getAccessToken();
    final turmas = await _turmaRepo.listar();
    final mapTurma = <String, List<String>>{};
    for (final t in turmas) {
      mapTurma[t.id] = await _turmaRepo.alunoIdsPorTurma(t.id);
    }
    final results = await Future.wait([
      _mensRepo.listar(mes: _mes, ano: _ano),
      _mensRepo.listar(ano: _ano),
      _alunoRepo.listar(ativo: true),
      _configRepo.obter(),
    ]);
    if (mounted) setState(() {
      _mensalidades = results[0] as List<Mensalidade>;
      _mensalidadesAno = results[1] as List<Mensalidade>;
      _alunos = results[2] as List<Aluno>;
      _config = results[3] as FinanceiroConfig;
      _turmas = turmas;
      _alunoIdsPorTurma = mapTurma;
      _mpConfigurado = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  List<Aluno> get _alunosCobranca =>
      _alunos.where((a) => a.cadastroValidado && a.cobrancaAtiva).toList();

  double _valorAluno(Aluno a) => calcularValorMensalidadeAluno(a, _config, _alunosCobranca);

  // Helpers
  double get _totalArrecadado => _mensalidades.where((m) => m.status == 'pago').fold(0, (s, m) => s + m.valor);
  double get _totalEsperado => _alunosCobranca.fold(0, (s, a) => s + _valorAluno(a));
  List<Aluno> get _alunosPagos => _alunos.where((a) => _mensalidades.any((m) => m.alunoId == a.id && m.status == 'pago')).toList();
  List<Aluno> get _alunosNaoPagos => _alunos.where((a) => !_mensalidades.any((m) => m.alunoId == a.id && m.status == 'pago')).toList();
  int get _diaAtual => DateTime.now().month == _mes && DateTime.now().year == _ano ? DateTime.now().day : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Valores e descontos',
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const FinanceiroConfigScreen()),
              );
              if (ok == true) _load();
            },
          ),
          IconButton(icon: const Icon(Icons.settings_outlined), tooltip: 'Mercado Pago',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const MpConfigScreen()));
              _load();
            }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Painel'),
            Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Mensalidades'),
            Tab(icon: Icon(Icons.payment, size: 18), text: 'Cobranças MP'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : TabBarView(
              controller: _tabs,
              children: [
                _PainelBI(
                  alunos: _alunos,
                  alunosCobranca: _alunosCobranca,
                  mensalidades: _mensalidades,
                  mensalidadesAno: _mensalidadesAno,
                  config: _config,
                  turmas: _turmas,
                  alunoIdsPorTurma: _alunoIdsPorTurma,
                  mes: _mes,
                  ano: _ano,
                  diaAtual: _diaAtual,
                  totalArrecadado: _totalArrecadado,
                  totalEsperado: _totalEsperado,
                  alunosPagos: _alunosPagos,
                  alunosNaoPagos: _alunosNaoPagos,
                  valorAluno: _valorAluno,
                  onEditarRegras: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const FinanceiroConfigScreen()),
                    );
                    if (ok == true) _load();
                  },
                  onChangeMes: (m, a) { setState(() { _mes = m; _ano = a; }); _load(); },
                ),
                _MensalidadesTab(
                  alunos: _alunos,
                  mensalidades: _mensalidades,
                  mes: _mes,
                  ano: _ano,
                  config: _config,
                  totalArrecadado: _totalArrecadado,
                  pendentes: _mensalidades.where((m) => m.status != 'pago').length,
                  valorAluno: _valorAluno,
                  onRefresh: _load,
                  onChangeMes: (m, a) { setState(() { _mes = m; _ano = a; }); _load(); },
                ),
                _MpTab(
                  alunos: _alunos,
                  mensalidades: _mensalidades,
                  mes: _mes,
                  ano: _ano,
                  mpConfigurado: _mpConfigurado,
                  alunosNaoPagos: _alunosNaoPagos,
                  valorAluno: _valorAluno,
                  onRefresh: _load,
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// PAINEL DE BI
// ─────────────────────────────────────────────
class _PainelBI extends StatelessWidget {
  final List<Aluno> alunos, alunosCobranca, alunosPagos, alunosNaoPagos;
  final List<Mensalidade> mensalidades, mensalidadesAno;
  final List<Turma> turmas;
  final Map<String, List<String>> alunoIdsPorTurma;
  final FinanceiroConfig config;
  final int mes, ano, diaAtual;
  final double totalArrecadado, totalEsperado;
  final double Function(Aluno) valorAluno;
  final VoidCallback onEditarRegras;
  final Function(int mes, int ano) onChangeMes;

  const _PainelBI({
    required this.alunos,
    required this.alunosCobranca,
    required this.mensalidades,
    required this.mensalidadesAno,
    required this.config,
    required this.turmas,
    required this.alunoIdsPorTurma,
    required this.mes,
    required this.ano,
    required this.diaAtual,
    required this.totalArrecadado,
    required this.totalEsperado,
    required this.alunosPagos,
    required this.alunosNaoPagos,
    required this.valorAluno,
    required this.onEditarRegras,
    required this.onChangeMes,
  });

  double get _pctPagos => alunosCobranca.isEmpty ? 0 : alunosPagos.length / alunosCobranca.length;
  double get _inadimplencia => alunosCobranca.isEmpty ? 0 : alunosNaoPagos.length / alunosCobranca.length;
  double get _pctArrecadado => totalEsperado == 0 ? 0 : totalArrecadado / totalEsperado;

  @override
  Widget build(BuildContext context) {
    final mesNome = meses[mes - 1];
    final anoAtual = DateTime.now().year;
    final venc = config.diaVencimento;

    final proj = calcularProjecao(
      alunosAtivos: alunos,
      config: config,
      mensalidadesAno: mensalidadesAno,
      alunoIdsPorTurma: alunoIdsPorTurma,
      turmas: turmas,
      mesRef: mes,
      anoRef: ano,
    );

    // Alertas
    final alertas = <_Alerta>[];
    if (diaAtual >= venc && alunosNaoPagos.isNotEmpty) {
      alertas.add(_Alerta(cor: Colors.red, icon: Icons.warning_rounded,
          texto: '${alunosNaoPagos.length} aluno(s) em atraso — vencimento foi dia $venc'));
    } else if (diaAtual >= 5 && diaAtual < venc && alunosNaoPagos.isNotEmpty) {
      alertas.add(_Alerta(cor: Colors.orange, icon: Icons.schedule,
          texto: '${alunosNaoPagos.length} aluno(s) vencem em ${venc - diaAtual} dias'));
    } else if (diaAtual == 1 && alunosNaoPagos.isNotEmpty) {
      alertas.add(_Alerta(cor: Colors.blue, icon: Icons.info_outline,
          texto: 'Início do mês: ${alunosNaoPagos.length} mensalidade(s) pendentes'));
    }
    if (_inadimplencia > 0.3) {
      alertas.add(_Alerta(cor: Colors.red.shade900, icon: Icons.trending_down,
          texto: 'Inadimplência acima de 30% — atenção!'));
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Seletor de mês
      Row(children: [
        Expanded(child: DropdownButtonFormField<int>(
          value: mes,
          decoration: const InputDecoration(labelText: 'Mês', isDense: true),
          items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(meses[i]))),
          onChanged: (v) => onChangeMes(v!, ano),
        )),
        const SizedBox(width: 12),
        Expanded(child: DropdownButtonFormField<int>(
          value: ano,
          decoration: const InputDecoration(labelText: 'Ano', isDense: true),
          items: [anoAtual - 1, anoAtual, anoAtual + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
          onChanged: (v) => onChangeMes(mes, v!),
        )),
      ]),
      const SizedBox(height: 16),

      // Alertas
      if (alertas.isNotEmpty) ...alertas.map((a) => _AlertaBanner(alerta: a)),

      // KPIs principais
      Row(children: [
        Expanded(child: _KpiTile(
          titulo: 'Receita/mês',
          valor: 'R\$ ${proj.receitaMensalTotal.toStringAsFixed(0)}',
          icone: Icons.trending_up,
          cor: Colors.green,
        )),
        const SizedBox(width: 8),
        Expanded(child: _KpiTile(
          titulo: 'Projeção ano',
          valor: 'R\$ ${proj.projecaoPositivaAno.toStringAsFixed(0)}',
          icone: Icons.calendar_month,
          cor: Colors.teal,
        )),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _KpiTile(
          titulo: 'Risco (pend.)',
          valor: 'R\$ ${proj.riscoInadimplencia.toStringAsFixed(0)}',
          icone: Icons.trending_down,
          cor: Colors.red,
        )),
        const SizedBox(width: 8),
        Expanded(child: _KpiTile(
          titulo: 'Inadimplência',
          valor: '${(_inadimplencia * 100).toStringAsFixed(0)}%',
          icone: Icons.pie_chart_outline,
          cor: _inadimplencia > 0.3 ? Colors.red : Colors.orange,
        )),
      ]),
      const SizedBox(height: 12),

      _BiCard(
        child: Column(children: [
          _BiRow(label: 'Alunos com cobrança', value: '${alunosCobranca.length}', icon: Icons.people),
          _BiRow(label: 'Mensalidade esperada ($mesNome)', value: 'R\$ ${totalEsperado.toStringAsFixed(2)}', icon: Icons.calculate_outlined),
          _BiRow(label: 'Arrecadado em $mesNome', value: 'R\$ ${totalArrecadado.toStringAsFixed(2)}', icon: Icons.attach_money, cor: Colors.green),
          _BiRow(label: 'Gap do mês', value: 'R\$ ${proj.gapMesAtual.toStringAsFixed(2)}', icon: Icons.remove_circle_outline, cor: proj.gapMesAtual > 0 ? Colors.red : Colors.green),
        ]),
      ),
      const SizedBox(height: 12),

      if (proj.porTurma.any((p) => p.qtdAlunos > 0)) ...[
        _BiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Projeção por turma', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...proj.porTurma.where((p) => p.qtdAlunos > 0).take(8).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text('${p.turma.nome} (${p.qtdAlunos})', style: const TextStyle(fontSize: 12))),
                  Text('R\$ ${p.receitaMensal.toStringAsFixed(0)}/mês', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('+${p.receitaAnoRestante.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
                ]),
              )),
        ])),
        const SizedBox(height: 12),
      ],

      // Barras de progresso
      _BiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Arrecadação do mês', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _ProgressBar(value: _pctArrecadado, cor: Colors.green,
            label: '${(_pctArrecadado * 100).toStringAsFixed(0)}% do esperado'),
        const SizedBox(height: 16),
        const Text('Pagantes vs Inadimplentes', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _DoublProgressBar(pctPago: _pctPagos),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('✅ Pagos: ${alunosPagos.length} (${(_pctPagos * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
          Text('❌ Não pagos: ${alunosNaoPagos.length} (${(_inadimplencia * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
        ]),
      ])),
      const SizedBox(height: 12),

      // Grid de alunos por status
      _BiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Status por Aluno', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('$mesNome/$ano', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...alunosPagos.map((a) => _AlunoChip(nome: a.nome, pago: true)),
          ...alunosNaoPagos.map((a) => _AlunoChip(
            nome: a.nome, pago: false,
            atrasado: diaAtual > 10,
          )),
        ]),
      ])),
      const SizedBox(height: 12),

      _BiCard(
        child: InkWell(
          onTap: onEditarRegras,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Regras de Cobrança', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  TextButton.icon(
                    onPressed: onEditarRegras,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(foregroundColor: verdeEscuro),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BiRow(label: 'Vencimento mensal', value: 'Dia $venc', icon: Icons.event),
              _BiRow(label: 'Valor adulto', value: 'R\$ ${config.valorAdulto.toStringAsFixed(2)}', icon: Icons.person),
              _BiRow(label: 'Valor menor de 18', value: 'R\$ ${config.valorMenor.toStringAsFixed(2)}', icon: Icons.child_care),
              _BiRow(label: '2º familiar', value: '${config.desconto2oFamiliarPercent.toStringAsFixed(0)}% off', icon: Icons.family_restroom),
              _BiRow(label: '3º+ familiar', value: '${config.desconto3oFamiliarPercent.toStringAsFixed(0)}% off', icon: Icons.groups),
              _BiRow(label: 'Mesmo pagante', value: '${config.descontoMesmoPagantePercent.toStringAsFixed(0)}% off', icon: Icons.account_balance_wallet),
              _BiRow(label: 'Bolsistas', value: 'Até 100% no cadastro', icon: Icons.school, cor: Colors.blue),
              ...config.regrasExtras.where((r) => r.ativa).map(
                    (r) => _BiRow(label: r.titulo, value: r.valorExibicao, icon: Icons.rule),
                  ),
              const SizedBox(height: 4),
              Text(
                'Toque em Editar para alterar valores ou criar nova regra.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 80),
    ]);
  }
}

class _Alerta {
  final Color cor;
  final IconData icon;
  final String texto;
  const _Alerta({required this.cor, required this.icon, required this.texto});
}

class _AlertaBanner extends StatelessWidget {
  final _Alerta alerta;
  const _AlertaBanner({required this.alerta});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: alerta.cor.withValues(alpha: 0.1),
      border: Border.all(color: alerta.cor.withValues(alpha: 0.4)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Icon(alerta.icon, color: alerta.cor, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(alerta.texto, style: TextStyle(color: alerta.cor, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}

class _BiCard extends StatelessWidget {
  final Widget child;
  const _BiCard({required this.child});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: child));
}

class _KpiTile extends StatelessWidget {
  final String titulo, valor;
  final IconData icone;
  final Color cor;
  const _KpiTile({required this.titulo, required this.valor, required this.icone, required this.cor});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(height: 6),
            Text(titulo, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cor)),
          ]),
        ),
      );
}

class _BiRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? cor;
  const _BiRow({required this.label, required this.value, required this.icon, this.cor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 16, color: Colors.grey.shade500),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cor ?? Colors.black87)),
    ]),
  );
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color cor;
  final String label;
  const _ProgressBar({required this.value, required this.cor, required this.label});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0), minHeight: 14,
      backgroundColor: Colors.grey.shade200, color: cor,
    )),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
  ]);
}

class _DoublProgressBar extends StatelessWidget {
  final double pctPago;
  const _DoublProgressBar({required this.pctPago});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(height: 18, child: Row(children: [
      Expanded(flex: (pctPago * 100).round(), child: Container(color: Colors.green)),
      Expanded(flex: ((1 - pctPago) * 100).round().clamp(1, 100), child: Container(color: Colors.red.shade400)),
    ])),
  );
}

class _AlunoChip extends StatelessWidget {
  final String nome;
  final bool pago, atrasado;
  const _AlunoChip({required this.nome, required this.pago, this.atrasado = false});
  @override
  Widget build(BuildContext context) {
    final Color bg = pago ? Colors.green.shade50 : (atrasado ? Colors.red.shade50 : Colors.orange.shade50);
    final Color border = pago ? Colors.green : (atrasado ? Colors.red : Colors.orange);
    final Color text = pago ? Colors.green.shade800 : (atrasado ? Colors.red.shade800 : Colors.orange.shade800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(pago ? Icons.check_circle : (atrasado ? Icons.cancel : Icons.schedule), size: 13, color: border),
        const SizedBox(width: 4),
        Text(nome.split(' ').first, style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// ABA DE MENSALIDADES (existente)
// ─────────────────────────────────────────────
class _MensalidadesTab extends StatelessWidget {
  final List<Aluno> alunos;
  final List<Mensalidade> mensalidades;
  final int mes, ano, pendentes;
  final FinanceiroConfig config;
  final double totalArrecadado;
  final double Function(Aluno) valorAluno;
  final VoidCallback onRefresh;
  final Function(int, int) onChangeMes;

  const _MensalidadesTab({
    required this.alunos,
    required this.mensalidades,
    required this.mes,
    required this.ano,
    required this.config,
    required this.totalArrecadado,
    required this.pendentes,
    required this.valorAluno,
    required this.onRefresh,
    required this.onChangeMes,
  });

  @override
  Widget build(BuildContext context) {
    final repo = MensalidadeRepository();
    final anoAtual = DateTime.now().year;

    Future<void> marcarPago(Mensalidade m) async {
      await repo.marcarPago(m.id);
      onRefresh();
    }

    Future<void> desfazer(Mensalidade m) async {
      await repo.atualizar(m.copyWith(status: 'pendente', dataPagamento: null));
      onRefresh();
    }

    Future<void> deletar(Mensalidade m) async {
      final ok = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(content: const Text('Remover registro?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
          ]));
      if (ok == true) { await repo.deletar(m.id); onRefresh(); }
    }

    return Column(children: [
      Container(color: Colors.white, padding: const EdgeInsets.all(14), child: Column(children: [
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(
            value: mes, decoration: const InputDecoration(labelText: 'Mês', isDense: true),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(meses[i]))),
            onChanged: (v) => onChangeMes(v!, ano),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<int>(
            value: ano, decoration: const InputDecoration(labelText: 'Ano', isDense: true),
            items: [anoAtual - 1, anoAtual, anoAtual + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) => onChangeMes(mes, v!),
          )),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Arrecadado', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text('R\$ ${totalArrecadado.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Pendentes', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text('$pendentes', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.orange)),
          ]),
        ]),
      ])),
      CobrancaWhatsAppBanner(
        mes: mes,
        ano: ano,
        diaVencimento: config.diaVencimento,
        diasWhatsAppExtras: config.diasWhatsAppExtras,
        mensalidades: mensalidades,
        alunos: alunos,
        mesAtualSelecionado: mes == DateTime.now().month && ano == DateTime.now().year,
      ),
      Expanded(child: mensalidades.isEmpty
          ? Center(child: Text('Nenhum registro para ${meses[mes - 1]}/$ano', style: TextStyle(color: Colors.grey.shade500)))
          : RefreshIndicator(onRefresh: () async => onRefresh(), child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: mensalidades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final m = mensalidades[i];
                final aluno = alunos.firstWhere((a) => a.id == m.alunoId, orElse: () => Aluno(id: '', nome: m.alunoNome ?? '?'));
                return _MensalidadeCard(
                  mensalidade: m,
                  aluno: aluno,
                  diaVencimento: config.diaVencimento,
                  onPago: m.status != 'pago' ? () => marcarPago(m) : null,
                  onDesfazer: m.status == 'pago' ? () => desfazer(m) : null,
                  onDelete: () => deletar(m),
                  onWhatsapp: (tipo) => enviarCobranca(
                    tipo: tipo,
                    aluno: aluno,
                    mes: mes,
                    ano: ano,
                    valor: m.valor,
                    diaVencimento: config.diaVencimento,
                  ),
                );
              },
            ))),
      // Botão nova mensalidade
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
        child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () async {
            await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _NovaMensalidadeSheet(
                    alunos: alunos,
                    mes: mes,
                    ano: ano,
                    valorAluno: valorAluno,
                    onSaved: onRefresh,
                  ));
          },
          icon: const Icon(Icons.add),
          label: const Text('Nova Mensalidade'),
        )),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
// ABA MERCADO PAGO
// ─────────────────────────────────────────────
class _MpTab extends StatefulWidget {
  final List<Aluno> alunos, alunosNaoPagos;
  final List<Mensalidade> mensalidades;
  final int mes, ano;
  final bool mpConfigurado;
  final double Function(Aluno) valorAluno;
  final VoidCallback onRefresh;

  const _MpTab({
    required this.alunos,
    required this.mensalidades,
    required this.mes,
    required this.ano,
    required this.mpConfigurado,
    required this.alunosNaoPagos,
    required this.valorAluno,
    required this.onRefresh,
  });

  @override
  State<_MpTab> createState() => _MpTabState();
}

class _MpTabState extends State<_MpTab> {
  final Map<String, bool> _loadingMap = {};

  Future<void> _cobrarAluno(Aluno aluno) async {
    setState(() => _loadingMap[aluno.id] = true);
    final mensList = widget.mensalidades.where((m) => m.alunoId == aluno.id);
    final valor = mensList.isEmpty ? widget.valorAluno(aluno) : mensList.first.valor;
    final mesNome = meses[widget.mes - 1];

    final pref = await MercadoPagoService.instance.criarCobranca(
      titulo: 'Mensalidade $mesNome/${widget.ano} — ${aluno.nome}',
      valor: valor,
      emailPagador: aluno.email,
      descricao: 'SM BJJ — Academia de Jiu-Jitsu',
      metadados: {'aluno_id': aluno.id, 'mes': '${widget.mes}', 'ano': '${widget.ano}'},
    );

    setState(() => _loadingMap[aluno.id] = false);

    if (!mounted) return;

    if (pref == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao gerar cobrança. Verifique o token do Mercado Pago.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Mostra opções: abrir link ou compartilhar via WhatsApp
    showModalBottomSheet(context: context, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LinkSheet(aluno: aluno, pref: pref, mes: widget.mes, ano: widget.ano, valor: valor),
    );
  }

  Future<void> _cobrarAvulso() async {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CobrancaAvulsaSheet(alunos: widget.alunos),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.mpConfigurado) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.payment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Mercado Pago não configurado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Configure seu Access Token para gerar cobranças e links de pagamento.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const MpConfigScreen()));
              widget.onRefresh();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Configurar Mercado Pago'),
          ),
        ]),
      ));
    }

    final mesNome = meses[widget.mes - 1];

    return ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 80), children: [
      // Cobrança avulsa
      Card(
        color: verdeEscuro.withValues(alpha: 0.05),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: verdeEscuro, child: Icon(Icons.add, color: Colors.white)),
          title: const Text('Cobrança Avulsa', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Loja, evento, taxa ou outro'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _cobrarAvulso,
        ),
      ),
      const SizedBox(height: 16),

      Text('Mensalidades pendentes — $mesNome/${widget.ano}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 8),

      if (widget.alunosNaoPagos.isEmpty)
        Card(child: Padding(padding: const EdgeInsets.all(20),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text('Todos em dia em $mesNome!', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ]),
        ))
      else
        ...widget.alunosNaoPagos.map((a) {
          final tel = a.telefoneResponsavel ?? a.telefone;
          final mens = widget.mensalidades.where((m) => m.alunoId == a.id);
          final valor = mens.isEmpty ? widget.valorAluno(a) : mens.first.valor;
          final carregando = _loadingMap[a.id] ?? false;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                CircleAvatar(backgroundColor: Colors.red.shade100, radius: 22,
                  child: Text(a.nome[0], style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('R\$ ${valor.toStringAsFixed(2)}${tel == null ? ' · Sem telefone' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ])),
                if (carregando)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: verdeEscuro))
                else
                  ElevatedButton.icon(
                    onPressed: () => _cobrarAluno(a),
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Cobrar'),
                    style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
              ]),
            ),
          );
        }),
    ]);
  }
}

class _LinkSheet extends StatelessWidget {
  final Aluno aluno;
  final MpPreferencia pref;
  final int mes, ano;
  final double valor;
  const _LinkSheet({required this.aluno, required this.pref, required this.mes, required this.ano, required this.valor});

  @override
  Widget build(BuildContext context) {
    final mesNome = meses[mes - 1];
    final tel = aluno.telefoneResponsavel ?? aluno.telefone;

    Future<void> abrirLink() async {
      final uri = Uri.parse(pref.link);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    Future<void> enviarWhatsApp() async {
      if (tel == null) return;
      final msg = 'Olá, ${aluno.nomeResponsavel ?? aluno.nome}! 😊\n\n'
          'Segue o link para pagamento da mensalidade de *$mesNome/$ano* da SM BJJ:\n\n'
          '💰 Valor: *R\$ ${valor.toStringAsFixed(2)}*\n\n'
          '🔗 Link de pagamento:\n${pref.link}\n\n'
          'Aceitamos PIX, cartão e boleto pelo link! 🥋';
      await abrirWhatsApp(tel, msg);
      if (context.mounted) Navigator.pop(context);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 48),
        const SizedBox(height: 8),
        const Text('Cobrança gerada!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${aluno.nome} — R\$ ${valor.toStringAsFixed(2)}',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        if (tel != null) ElevatedButton.icon(
          onPressed: enviarWhatsApp,
          icon: const Icon(Icons.message),
          label: const Text('Enviar via WhatsApp'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: abrirLink,
          icon: const Icon(Icons.open_in_browser),
          label: const Text('Abrir link no navegador'),
          style: OutlinedButton.styleFrom(foregroundColor: verdeEscuro),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ]),
    );
  }
}

class _CobrancaAvulsaSheet extends StatefulWidget {
  final List<Aluno> alunos;
  const _CobrancaAvulsaSheet({required this.alunos});
  @override
  State<_CobrancaAvulsaSheet> createState() => _CobrancaAvulsaSheetState();
}

class _CobrancaAvulsaSheetState extends State<_CobrancaAvulsaSheet> {
  Aluno? _aluno;
  final _tituloCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _gerar() async {
    if (_tituloCtrl.text.isEmpty || _valorCtrl.text.isEmpty) return;
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) return;
    setState(() => _loading = true);

    final pref = await MercadoPagoService.instance.criarCobranca(
      titulo: _tituloCtrl.text.trim(),
      valor: valor,
      emailPagador: _aluno?.email,
      descricao: 'SM BJJ — Cobrança avulsa',
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (pref == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao gerar cobrança.'), backgroundColor: Colors.red));
      return;
    }

    Navigator.pop(context);

    // Abre link
    final uri = Uri.parse(pref.link);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);

    // Se tem aluno com telefone, oferece WhatsApp
    if (_aluno != null) {
      final tel = _aluno!.telefoneResponsavel ?? _aluno!.telefone;
      if (tel != null && context.mounted) {
        final msg = 'Olá! Segue o link de pagamento da SM BJJ:\n\n'
            '📋 *${_tituloCtrl.text.trim()}*\n'
            '💰 Valor: *R\$ ${valor.toStringAsFixed(2)}*\n\n'
            '🔗 ${pref.link}\n\nAceitamos PIX, cartão e boleto! 🥋';
        await abrirWhatsApp(tel, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Cobrança Avulsa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        DropdownButtonFormField<Aluno>(
          decoration: const InputDecoration(labelText: 'Aluno (opcional)', isDense: true),
          items: [const DropdownMenuItem(value: null, child: Text('— Sem vínculo —')),
            ...widget.alunos.map((a) => DropdownMenuItem(value: a, child: Text(a.nome)))],
          onChanged: (a) => setState(() => _aluno = a),
        ),
        const SizedBox(height: 12),
        TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Descrição *', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: _valorCtrl, decoration: const InputDecoration(labelText: 'Valor (R\$) *', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loading ? null : _gerar,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.link),
          label: const Text('Gerar Link de Pagamento'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// MENSALIDADE CARD (reaproveitado)
// ─────────────────────────────────────────────
class _MensalidadeCard extends StatelessWidget {
  final Mensalidade mensalidade;
  final Aluno aluno;
  final int diaVencimento;
  final VoidCallback? onPago, onDesfazer, onDelete;
  final Function(String) onWhatsapp;

  const _MensalidadeCard({
    required this.mensalidade,
    required this.aluno,
    required this.diaVencimento,
    this.onPago,
    this.onDesfazer,
    required this.onDelete,
    required this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    Color cor; IconData icon; String label;
    switch (mensalidade.status) {
      case 'pago': cor = Colors.green; icon = Icons.check_circle; label = 'Pago'; break;
      case 'atrasado': cor = Colors.red; icon = Icons.error; label = 'Atrasado'; break;
      default: cor = Colors.orange; icon = Icons.schedule; label = 'Pendente';
    }
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: cor, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mensalidade.alunoNome ?? aluno.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (mensalidade.dataPagamento != null)
            Text('Pago em ${mensalidade.dataPagamento}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          else if (mensalidade.observacao != null)
            Text(mensalidade.observacao!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('R\$ ${mensalidade.valor.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
        ]),
      ]),
      if (mensalidade.status != 'pago') ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: onPago, icon: const Icon(Icons.check, size: 16), label: const Text('Marcar Pago'), style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact))),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: onWhatsapp,
            icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.message, color: Colors.green, size: 18)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'aviso1', child: Text(labelTipoCobranca('aviso1', diaVencimento))),
              PopupMenuItem(value: 'aviso5', child: Text(labelTipoCobranca('aviso5', diaVencimento))),
              PopupMenuItem(value: 'vencimento', child: Text(labelTipoCobranca('vencimento', diaVencimento))),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
        ]),
      ] else
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: onDesfazer, child: const Text('Desfazer', style: TextStyle(color: Colors.grey))),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
        ]),
    ])));
  }
}

// ─────────────────────────────────────────────
// SHEET NOVA MENSALIDADE
// ─────────────────────────────────────────────
class _NovaMensalidadeSheet extends StatefulWidget {
  final List<Aluno> alunos;
  final int mes, ano;
  final double Function(Aluno) valorAluno;
  final VoidCallback onSaved;
  const _NovaMensalidadeSheet({
    required this.alunos,
    required this.mes,
    required this.ano,
    required this.valorAluno,
    required this.onSaved,
  });
  @override
  State<_NovaMensalidadeSheet> createState() => _NovaMensalidadeSheetState();
}

class _NovaMensalidadeSheetState extends State<_NovaMensalidadeSheet> {
  final _repo = MensalidadeRepository();
  final _uuid = const Uuid();
  Aluno? _aluno;
  late int _mes = widget.mes;
  late int _ano = widget.ano;
  late double _valor = valorCheio;
  String _status = 'pendente';
  String _obs = '';
  bool _loading = false;

  Future<void> _salvar() async {
    if (_aluno == null) return;
    setState(() => _loading = true);
    await _repo.criar(Mensalidade(
      id: _uuid.v4(), alunoId: _aluno!.id, alunoNome: _aluno!.nome,
      mes: _mes, ano: _ano, valor: _valor, status: _status,
      dataPagamento: _status == 'pago' ? DateTime.now().toIso8601String().split('T')[0] : null,
      observacao: _obs.isEmpty ? null : _obs,
    ));
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Nova Mensalidade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        DropdownButtonFormField<Aluno>(
          decoration: const InputDecoration(labelText: 'Aluno *', isDense: true),
          items: widget.alunos.map((a) => DropdownMenuItem(value: a, child: Text('${a.nome} – R\$ ${widget.valorAluno(a).toStringAsFixed(2)}'))).toList(),
          onChanged: (a) => setState(() { _aluno = a; if (a != null) _valor = widget.valorAluno(a); }),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(value: _mes, decoration: const InputDecoration(labelText: 'Mês', isDense: true),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(meses[i]))), onChanged: (v) => setState(() => _mes = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<int>(value: _ano, decoration: const InputDecoration(labelText: 'Ano', isDense: true),
            items: [_ano - 1, _ano, _ano + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(), onChanged: (v) => setState(() => _ano = v!))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(initialValue: _valor.toStringAsFixed(2), decoration: const InputDecoration(labelText: 'Valor (R\$)', isDense: true), keyboardType: TextInputType.number, onChanged: (v) => _valor = double.tryParse(v) ?? _valor)),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: const [DropdownMenuItem(value: 'pendente', child: Text('Pendente')), DropdownMenuItem(value: 'pago', child: Text('Pago')), DropdownMenuItem(value: 'atrasado', child: Text('Atrasado'))],
            onChanged: (v) => setState(() => _status = v!))),
        ]),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: 'Observação', isDense: true), onChanged: (v) => _obs = v),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _salvar,
          child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar'),
        ),
      ]),
    );
  }
}
