import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Explosão de fogos/confetes na tela do aniversariante.
class AniversarioCelebrationOverlay extends StatefulWidget {
  final String nome;
  final VoidCallback onDismiss;

  const AniversarioCelebrationOverlay({
    super.key,
    required this.nome,
    required this.onDismiss,
  });

  @override
  State<AniversarioCelebrationOverlay> createState() => _AniversarioCelebrationOverlayState();
}

class _AniversarioCelebrationOverlayState extends State<AniversarioCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _confetti;
  late final AnimationController _banner;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(72, (_) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 120 + rng.nextDouble() * 280;
      return _Particle(
        dx: math.cos(angle) * speed,
        dy: math.sin(angle) * speed - 80,
        color: _cores[rng.nextInt(_cores.length)],
        size: 4 + rng.nextDouble() * 7,
        spin: (rng.nextDouble() - 0.5) * 8,
        shape: rng.nextInt(3),
      );
    });
    _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..forward();
    _banner = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  static const _cores = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
    Colors.white,
  ];

  @override
  void dispose() {
    _confetti.dispose();
    _banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primeiro = widget.nome.trim().split(RegExp(r'\s+')).first;
    return Material(
      color: Colors.black54,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _confetti,
            builder: (_, __) {
              return CustomPaint(
                painter: _ConfettiPainter(progress: _confetti.value, particles: _particles),
              );
            },
          ),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _banner, curve: Curves.elasticOut),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAD1457), Color(0xFFE91E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉🎂✨', style: TextStyle(fontSize: 34)),
                    const SizedBox(height: 8),
                    const Text(
                      'Feliz Aniversário!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      primeiro,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A academia SM BJJ deseja um dia incrível!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFAD1457),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: widget.onDismiss,
                      child: const Text('Obrigado!', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double dx;
  final double dy;
  final Color color;
  final double size;
  final double spin;
  final int shape;
  const _Particle({
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
    required this.spin,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final x = cx + p.dx * t;
      final y = cy + p.dy * t + 420 * t * t;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * progress * math.pi);
      switch (p.shape) {
        case 0:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case 1:
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), paint);
          break;
        default:
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 2, p.size / 2)
            ..lineTo(-p.size / 2, p.size / 2)
            ..close();
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Exibe o overlay de celebração uma vez (controlado pelo caller).
Future<void> mostrarCelebracaoAniversario(BuildContext context, String nome) async {
  if (!context.mounted) return;
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'aniversario',
    barrierColor: Colors.transparent,
    pageBuilder: (ctx, _, __) => AniversarioCelebrationOverlay(
      nome: nome,
      onDismiss: () => Navigator.of(ctx).pop(),
    ),
  );
}
