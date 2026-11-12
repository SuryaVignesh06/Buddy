import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// CustomPainter drawing expanding concentric ripple rings and an optional
/// flame-red impact shockwave ring from Dot's centre.
class RingsPainter extends CustomPainter {
  const RingsPainter({
    required this.progress,
    this.ringCount = 3,
    this.baseRadius = 46.0,
    this.maxSpread = 155.0,
    this.shockwaveProgress = 0.0,
  });

  final double progress; // 0..1 across listening phase
  final int ringCount;
  final double baseRadius;
  final double maxSpread;
  final double shockwaveProgress; // 0..1 during impact shockwave

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Impact shockwave ring in flameRed (1.0–1.25 s)
    if (shockwaveProgress > 0.0 && shockwaveProgress < 1.0) {
      final eased = Curves.easeOutCubic.transform(shockwaveProgress);
      final radius = baseRadius * 0.9 + eased * (maxSpread * 1.15);
      final alpha = (1.0 - eased) * 0.85;
      final shockPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (4.5 - eased * 3.0).clamp(1.2, 4.5)
        ..color = OrbitTokens.flameRed.withValues(alpha: alpha);
      canvas.drawCircle(center, radius, shockPaint);
    }

    if (progress <= 0.0) return;

    for (var i = 0; i < ringCount; i++) {
      final stagger = i * 0.22;
      final localT = ((progress - stagger) / 0.68).clamp(0.0, 1.0);
      if (localT <= 0.0 || localT >= 1.0) continue;

      final eased = Curves.easeOutCubic.transform(localT);
      final radius = baseRadius + eased * maxSpread;
      final opacity = (1.0 - eased) * 0.30;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - eased * 0.9
        ..color = Color.lerp(
          OrbitTokens.orange,
          Colors.white,
          0.55,
        )!
            .withValues(alpha: opacity);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RingsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringCount != ringCount ||
        oldDelegate.baseRadius != baseRadius ||
        oldDelegate.maxSpread != maxSpread ||
        oldDelegate.shockwaveProgress != shockwaveProgress;
  }
}
