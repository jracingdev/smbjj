import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_version.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/gft_logo_image.dart';

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o App')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(children: [

          // Logo SM BJJ
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.asset('assets/images/logo.png', width: 100, height: 100, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: verdeEscuro, borderRadius: BorderRadius.circular(60)),
                child: const Icon(Icons.sports_martial_arts, size: 48, color: Colors.white),
              )),
          ),
          const SizedBox(height: 12),
          const Text('CT SM BJJ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: verdeEscuro)),
          Text('Academia de Jiu-Jitsu · desde $academiaFundacao',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 6),
          Text('Versão ${AppVersion.version} (build ${AppVersion.build})',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),

          const SizedBox(height: 24),

          // GFT Team
          _Card(child: Column(children: [
            const GftLogoImage(height: 96),
            const SizedBox(height: 12),
            const Text('ACADEMIA CREDENCIADA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1)),
            const SizedBox(height: 4),
            const Text(academiaCredenciada,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: verdeEscuro),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: verdeEscuro.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text(academiaCredencial,
                  style: TextStyle(fontWeight: FontWeight.w800, color: verdeEscuro, fontSize: 14)),
            ),
          ])),

          const SizedBox(height: 16),

          // Professor
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.military_tech, color: verdeEscuro),
              const SizedBox(width: 8),
              const Text('Professor Responsável', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const Divider(height: 16),
            _infoRow(Icons.person, professorNome),
            _infoRow(Icons.grade, professorGraduacao),
            _infoRow(Icons.badge_outlined, 'Registro: $professorRegistro'),
          ])),

          const SizedBox(height: 16),

          // Desenvolvedor (discreto)
          _Card(
            color: Colors.grey.shade50,
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.code, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text('Desenvolvido por', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse('https://$developerUrl');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Text(developerNome,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: verdeEscuro,
                        decoration: TextDecoration.underline)),
              ),
              Text(developerUrl, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ),

          const SizedBox(height: 12),
          Text('© $academiaFundacao–${DateTime.now().year} CT SM BJJ · Todos os direitos reservados',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 16, color: Colors.grey.shade500),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
    ]),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _Card({required this.child, this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}
