import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/presenca/checkin_url.dart';
import '../../core/theme.dart';
import '../../models/presenca_token.dart';
import '../../models/turma.dart';
import '../../repositories/presenca_checkin_repository.dart';
import '../../utils/date_utils.dart';

/// Exibe QR em ~85% da tela para leitura à distância.
class QrDisplayScreen extends StatefulWidget {
  final String tipo;
  final Turma? turma;

  const QrDisplayScreen({
    super.key,
    required this.tipo,
    this.turma,
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  final _repo = PresencaCheckinRepository();
  PresencaToken? _token;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  Duration _restante = Duration.zero;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _gerarToken();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _gerarToken() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final tok = await _repo.criarToken(
        tipo: widget.tipo,
        turmaId: widget.turma?.id,
      );
      if (!mounted) return;
      setState(() {
        _token = tok;
        _loading = false;
        _restante = tok.validoAte.difference(DateTime.now());
      });
      _agendarRenovacao(tok);
      _iniciarCountdown();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = e.toString();
        });
      }
    }
  }

  void _agendarRenovacao(PresencaToken tok) {
    _refreshTimer?.cancel();
    final ms = tok.validoAte.difference(DateTime.now()).inMilliseconds - 5000;
    if (ms > 0) {
      _refreshTimer = Timer(Duration(milliseconds: ms), _gerarToken);
    }
  }

  void _iniciarCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_token == null || !mounted) return;
      final r = _token!.validoAte.difference(DateTime.now());
      setState(() => _restante = r.isNegative ? Duration.zero : r);
    });
  }

  String get _titulo {
    if (widget.tipo == 'unico') return 'QR único — todas as turmas';
    return widget.turma?.nome ?? 'Turma';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_titulo),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _gerarToken, tooltip: 'Novo QR'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: verdeEscuro))
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _gerarToken, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final side = constraints.biggest.shortestSide * 0.85;
                    final url = urlCheckinPresenca(_token!.token);
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Escaneie para registrar presença',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDataBr(_token!.dataAula),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: side,
                              height: side,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: verdeEscuro.withValues(alpha: 0.3), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: url,
                                version: QrVersions.auto,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            children: [
                              Text(
                                'Válido por mais ${_restante.inMinutes}:${(_restante.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: verdeEscuro,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.tipo == 'unico'
                                    ? 'Alunos de qualquer turma podem escanear este código.'
                                    : 'Somente alunos desta turma podem usar este QR.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
