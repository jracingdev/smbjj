import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/presenca_config.dart';
import '../../models/turma.dart';
import '../../repositories/presenca_config_repository.dart';
import '../../repositories/turma_repository.dart';
import 'chamada_screen.dart';
import 'qr_display_screen.dart';

/// Admin escolhe o método de presença e abre a ferramenta correspondente.
class PresencaAdminScreen extends StatefulWidget {
  const PresencaAdminScreen({super.key});

  @override
  State<PresencaAdminScreen> createState() => _PresencaAdminScreenState();
}

class _PresencaAdminScreenState extends State<PresencaAdminScreen> {
  final _configRepo = PresencaConfigRepository();
  final _turmaRepo = TurmaRepository();

  PresencaConfig _config = const PresencaConfig();
  List<Turma> _turmas = [];
  Turma? _turmaQr;
  bool _loading = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _configRepo.obter(),
        _turmaRepo.listar(),
      ]);
      if (!mounted) return;
      final turmas = results[1] as List<Turma>;
      setState(() {
        _config = results[0] as PresencaConfig;
        _turmas = turmas;
        _turmaQr = turmas.isNotEmpty ? turmas.first : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvarMetodo(MetodoPresenca metodo) async {
    setState(() => _salvando = true);
    try {
      final nova = PresencaConfig(
        metodo: metodo,
        tokenValidadeMinutos: _config.tokenValidadeMinutos,
      );
      await _configRepo.salvar(nova);
      if (mounted) setState(() => _config = nova);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirChamada() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChamadaScreen(turmaInicial: _turmaQr)),
    );
  }

  void _abrirQr({required bool unico}) {
    if (!unico && _turmaQr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma turma.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrDisplayScreen(
          tipo: unico ? 'unico' : 'turma',
          turma: unico ? null : _turmaQr,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presença nos treinos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Método de presença',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Escolha como os alunos registrarão presença hoje.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ...MetodoPresenca.values.map((m) {
                          final sel = _config.metodo == m;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: sel ? verdeEscuro.withValues(alpha: 0.08) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _salvando ? null : () => _salvarMetodo(m),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        sel ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: sel ? verdeEscuro : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(m.descricao, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _acaoPrincipal(),
              ],
            ),
    );
  }

  Widget _acaoPrincipal() {
    switch (_config.metodo) {
      case MetodoPresenca.chamada:
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: verdeEscuro,
              child: Icon(Icons.fact_check, color: Colors.white),
            ),
            title: const Text('Abrir chamada manual', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Marque presença aluno por aluno'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _abrirChamada,
          ),
        );

      case MetodoPresenca.qrTurma:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: DropdownButtonFormField<Turma>(
                  value: _turmaQr,
                  decoration: const InputDecoration(
                    labelText: 'Turma do QR',
                    border: OutlineInputBorder(),
                  ),
                  items: _turmas
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.nome)))
                      .toList(),
                  onChanged: (t) => setState(() => _turmaQr = t),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _abrirQr(unico: false),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Exibir QR da turma (tela cheia)'),
              style: FilledButton.styleFrom(
                backgroundColor: verdeEscuro,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exiba o QR em um tablet na academia. Cada turma tem seu próprio código.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _abrirChamada,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Chamada manual (backup)'),
            ),
          ],
        );

      case MetodoPresenca.qrUnico:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () => _abrirQr(unico: true),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Exibir QR único (tela cheia)'),
              style: FilledButton.styleFrom(
                backgroundColor: verdeEscuro,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Um único QR para todos os alunos. O sistema identifica a turma de cada um automaticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _abrirChamada,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Chamada manual (backup)'),
            ),
          ],
        );
    }
  }
}
