import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/graduacao.dart';
import '../../repositories/graduacao_repository.dart';
import '../../utils/date_utils.dart';
import '../../widgets/faixa_badge.dart';
import '../../widgets/historico_graduacoes_section.dart';

/// Listagem completa das faixas-pretas formadas pela academia.
class FaixasPretasScreen extends StatefulWidget {
  final bool isAdmin;
  const FaixasPretasScreen({super.key, this.isAdmin = false});

  @override
  State<FaixasPretasScreen> createState() => _FaixasPretasScreenState();
}

class _FaixasPretasScreenState extends State<FaixasPretasScreen> {
  final _repo = GraduacaoRepository();
  List<Graduacao> _itens = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listarPretasFormadas();
      if (mounted) setState(() { _itens = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faixas-pretas SM BJJ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : RefreshIndicator(
              onRefresh: _load,
              color: verdeEscuro,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.military_tech, color: Colors.amber.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Destaque: ${_itens.length} faixa${_itens.length == 1 ? '' : 's'}-preta${_itens.length == 1 ? '' : 's'} formada${_itens.length == 1 ? '' : 's'} na casa. O histórico de cada aluno mostra todas as faixas.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_itens.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          widget.isAdmin
                              ? 'Cadastre uma graduação de faixa preta e marque “Faixa-preta SM BJJ”.'
                              : 'Nenhuma faixa-preta formada cadastrada ainda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ..._itens.map((g) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              FaixaIlustracao(faixa: 'preta', grau: g.grau, width: 64, height: 12),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.alunoNome,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatDataBr(g.dataGraduacao)} · ${labelGrau(g.grau)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    if ((g.evento ?? '').trim().isNotEmpty ||
                                        (g.professor ?? '').trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          if ((g.professor ?? '').trim().isNotEmpty)
                                            'Prof. ${g.professor!.trim()}',
                                          if ((g.evento ?? '').trim().isNotEmpty) g.evento!.trim(),
                                        ].join(' · '),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.shade700),
                                      ),
                                      child: Text(
                                        'Formado(a) na casa',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.amber.shade300,
                                        ),
                                      ),
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
    );
  }
}
