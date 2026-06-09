import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/presenca_config.dart';
import '../screens/presenca/scan_qr_screen.dart';

class CheckinAlunoCard extends StatelessWidget {
  final MetodoPresenca metodo;

  const CheckinAlunoCard({super.key, required this.metodo});

  bool get _usaQr =>
      metodo == MetodoPresenca.qrTurma || metodo == MetodoPresenca.qrUnico;

  @override
  Widget build(BuildContext context) {
    if (!_usaQr) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: verdeEscuro),
                SizedBox(width: 8),
                Text('Registrar presença', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              metodo == MetodoPresenca.qrUnico
                  ? 'Ao chegar na academia, escaneie o QR único exibido pelo professor.'
                  : 'Ao chegar na academia, escaneie o QR da sua turma.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanQrScreen()),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear QR da aula'),
              style: FilledButton.styleFrom(backgroundColor: verdeEscuro),
            ),
            const SizedBox(height: 6),
            Text(
              'Também funciona escaneando com a câmera do celular — abre o link e confirma a presença.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
