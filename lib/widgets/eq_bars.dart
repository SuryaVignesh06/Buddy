import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Custom-painted equaliser bars driven by phase-shifted sine waves.
class EqBars extends StatelessWidget {
  const EqBars({
    super.key,
    required this.phase,
    this.barCount = 5,
    this.width = 48.0,
    this.height = 24.0,
    this.growth = 1.0,
    this.active = true,
  });

  final double phase;
  final int barCount;
  final double width;
  final double height;
  final double growth;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _EqBarsPainter(
            phase: phase,
            barCount: barCount,
            growth: growth,
            active: active,
          ),
        ),
      ),
    );
  }
}

class _EqBarsPainter extends CustomPainter {
  const _EqBarsPainter({
    required this.phase,
    required this.barCount,
    required this.growth,
    required this.active,
  });

  final double phase;
  final int barCount;
  final double growth;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (growth <= 0.01) return;
    final barWidth = (size.width / (barCount * 1.85)).clamp(2.5, 6.0);
    final gap = barCount > 1
        ? (size.width - barCount * barWidth) / (barCount - 1)
        : 0.0;

    final shader = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [OrbitTokens.accentHot, OrbitTokens.accent, OrbitTokens.amber],
    ).createShader(Offset.zero & size);

    final paint = Paint()..shader = shader;

    for (var i = 0; i < barCount; i++) {
      final wave = active
          ? 0.28 + 0.72 * (0.5 + 0.5 * math.sin(phase * math.pi * 2 + i * 1.15))
          : 0.22;
      final barHeight = (size.height * wave * growth).clamp(3.0, size.height);
      final left = i * (barWidth + gap);
      final rect = Rect.fromLTWH(
        left,
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqBarsPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.barCount != barCount ||
        oldDelegate.growth != growth ||
        oldDelegate.active != active;
  }
}
