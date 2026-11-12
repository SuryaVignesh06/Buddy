import 'package:flutter/material.dart';

import '../features/splash/rings_painter.dart';

/// Concentric animated ripple rings radiating outward from a focal point.
class RippleRings extends StatelessWidget {
  const RippleRings({
    super.key,
    required this.progress,
    this.size = 360.0,
    this.ringCount = 3,
    this.baseRadius = 46.0,
    this.maxSpread = 155.0,
    this.shockwaveProgress = 0.0,
  });

  final double progress;
  final double size;
  final int ringCount;
  final double baseRadius;
  final double maxSpread;
  final double shockwaveProgress;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: RingsPainter(
            progress: progress,
            ringCount: ringCount,
            baseRadius: baseRadius,
            maxSpread: maxSpread,
            shockwaveProgress: shockwaveProgress,
          ),
        ),
      ),
    );
  }
}
