import 'dart:math';

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BackgroundArt extends StatelessWidget {
  const BackgroundArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppPalette.canvas, AppPalette.wash],
              ),
            ),
          ),
          _GlowBlob(
            alignment: const Alignment(-0.9, -0.8),
            size: 320,
            colors: [
              AppPalette.accent.withValues(alpha: 0.22),
              AppPalette.canvas.withValues(alpha: 0.0),
            ],
          ),
          _GlowBlob(
            alignment: const Alignment(0.95, -0.6),
            size: 260,
            colors: [
              AppPalette.accentWarm.withValues(alpha: 0.25),
              AppPalette.canvas.withValues(alpha: 0.0),
            ],
          ),
          _NoiseOverlay(opacity: 0.05),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.size,
    required this.colors,
  });

  final Alignment alignment;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(painter: _NoisePainter()),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final random = Random(2);
    const density = 1800;
    for (var i = 0; i < density; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      paint.color = Colors.black.withValues(alpha: random.nextDouble() * 0.12);
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
