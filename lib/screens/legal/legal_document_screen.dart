import 'package:flutter/material.dart';
import '../../core/legal/legal_texts.dart';
import '../../core/theme.dart';

enum LegalDoc { termos, privacidade }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDoc documento;

  const LegalDocumentScreen({super.key, required this.documento});

  static Future<void> abrir(BuildContext context, LegalDoc doc) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LegalDocumentScreen(documento: doc)),
    );
  }

  String get _titulo => documento == LegalDoc.termos
      ? LegalTexts.termosTitulo
      : LegalTexts.privacidadeTitulo;

  String get _conteudo =>
      documento == LegalDoc.termos ? LegalTexts.termos : LegalTexts.privacidade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titulo)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: verdeEscuro.withValues(alpha: 0.15),
                    child: const Icon(Icons.sports_martial_arts, color: verdeEscuro),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: verdeEscuro)),
                    Text('CT SM BJJ · ${LegalTexts.dataAtualizacao}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _conteudo.trim(),
            style: TextStyle(fontSize: 14, height: 1.55, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}

/// Links compactos para termos e privacidade.
class LegalLinksRow extends StatelessWidget {
  final TextStyle? style;
  final MainAxisAlignment alignment;

  const LegalLinksRow({super.key, this.style, this.alignment = MainAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    final linkStyle = style ??
        TextStyle(fontSize: 12, color: Colors.grey.shade600, decoration: TextDecoration.underline);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        GestureDetector(
          onTap: () => LegalDocumentScreen.abrir(context, LegalDoc.termos),
          child: Text('Termos de Uso', style: linkStyle.copyWith(color: verdeEscuro, fontWeight: FontWeight.w600)),
        ),
        Text('·', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        GestureDetector(
          onTap: () => LegalDocumentScreen.abrir(context, LegalDoc.privacidade),
          child: Text('Política de Privacidade', style: linkStyle.copyWith(color: verdeEscuro, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
