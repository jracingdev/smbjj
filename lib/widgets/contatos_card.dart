import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// WhatsApp e Instagram do professor e do studio — visível para alunos.
class ContatosCard extends StatelessWidget {
  const ContatosCard({super.key});

  Future<void> _abrir(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone_outlined, color: verdeEscuro, size: 20),
                SizedBox(width: 8),
                Text('Fale conosco', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            _ContatoTile(
              icon: Icons.chat,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp do professor',
              subtitle: professorTelefoneExibicao,
              onTap: () => _abrir(Uri.parse('https://wa.me/$professorTelefone')),
            ),
            const Divider(height: 20),
            _ContatoTile(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFE1306C),
              label: 'Instagram — Professor',
              subtitle: '@$professorInstagram',
              onTap: () => _abrir(Uri.parse('https://instagram.com/$professorInstagram')),
            ),
            const Divider(height: 20),
            _ContatoTile(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFE1306C),
              label: 'Instagram — Studio',
              subtitle: '@$studioInstagram',
              onTap: () => _abrir(Uri.parse('https://instagram.com/$studioInstagram')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContatoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContatoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
