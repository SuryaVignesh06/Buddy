import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Deterministic geometric album/playlist artwork generated from a seed and two palette colours.
class GeneratedArt extends StatelessWidget {
  const GeneratedArt({
    super.key,
    required this.seed,
    required this.primaryColor,
    required this.secondaryColor,
    this.size,
    this.borderRadius = OrbitTokens.radiusCardArt,
    this.circular = false,
    this.brightness = 1.0,
    this.badgeIcon,
  });

  final int seed;
  final Color primaryColor;
  final Color secondaryColor;
  final double? size;
  final double borderRadius;
  final bool circular;
  final double brightness;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final shape = ClipRRect(
      borderRadius: BorderRadius.circular(
        circular ? OrbitTokens.radiusArtistArt : borderRadius,
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: size != null ? Size.square(size!) : Size.infinite,
          painter: _GeneratedArtPainter(
            seed: seed,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            brightness: brightness,
          ),
          child: badgeIcon != null
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      badgeIcon,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );

    if (size != null) {
      return SizedBox.square(dimension: size, child: shape);
    }
    return shape;
  }
}

class _GeneratedArtPainter extends CustomPainter {
  const _GeneratedArtPainter({
    required this.seed,
    required this.primaryColor,
    required this.secondaryColor,
    required this.brightness,
  });

  final int seed;
  final Color primaryColor;
  final Color secondaryColor;
  final double brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rng = math.Random(seed);

    // Rich diagonal base gradient
    final angle = (seed % 4) * (math.pi / 4);
    final begin = Alignment(math.cos(angle), math.sin(angle));
    final end = Alignment(-math.cos(angle), -math.sin(angle));
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Color.lerp(primaryColor, Colors.white, 0.12)!,
          primaryColor,
          secondaryColor,
          Color.lerp(secondaryColor, Colors.black, 0.45)!,
        ],
        stops: const [0.0, 0.35, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Subtle organic light orb
    final orbX = size.width * (0.25 + rng.nextDouble() * 0.55);
    final orbY = size.height * (0.20 + rng.nextDouble() * 0.55);
    final orbRadius = size.shortestSide * (0.45 + rng.nextDouble() * 0.35);
    final orbRect = Rect.fromCircle(center: Offset(orbX, orbY), radius: orbRadius);
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          OrbitTokens.emberLight.withValues(alpha: 0.42),
          primaryColor.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(orbRect);
    canvas.drawCircle(Offset(orbX, orbY), orbRadius, orbPaint);

    // Seeded geometric motif variant (concentric arcs, angled ribbons, or floating discs)
    final variant = seed.abs() % 3;
    if (variant == 0) {
      // Vinyl / orbital rings
      final center = Offset(
        size.width * (0.35 + rng.nextDouble() * 0.3),
        size.height * (0.35 + rng.nextDouble() * 0.3),
      );
      for (var i = 0; i < 4; i++) {
        final r = size.shortestSide * (0.18 + i * 0.14);
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (size.shortestSide * 0.025).clamp(1.0, 4.0)
          ..color = Colors.white.withValues(alpha: 0.16 - i * 0.03);
        canvas.drawCircle(center, r, ringPaint);
      }
    } else if (variant == 1) {
      // Tilted translucent panes
      for (var i = 0; i < 3; i++) {
        canvas.save();
        final cx = size.width * (0.25 + i * 0.25);
        final cy = size.height * (0.25 + rng.nextDouble() * 0.5);
        canvas.translate(cx, cy);
        canvas.rotate((rng.nextDouble() - 0.5) * 0.8);
        final paneRect = Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.55,
          height: size.height * 0.55,
        );
        final panePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.08 + i * 0.04);
        canvas.drawRRect(
          RRect.fromRectAndRadius(paneRect, Radius.circular(size.width * 0.08)),
          panePaint,
        );
        canvas.restore();
      }
    } else {
      // Soundwave bars / horizon bands
      final barCount = 5;
      final barW = size.width * 0.08;
      final startX = size.width * 0.22;
      for (var i = 0; i < barCount; i++) {
        final h = size.height * (0.22 + rng.nextDouble() * 0.45);
        final x = startX + i * barW * 1.5;
        final barRect = Rect.fromCenter(
          center: Offset(x, size.height * 0.55),
          width: barW,
          height: h,
        );
        final barPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.18);
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, Radius.circular(barW)),
          barPaint,
        );
      }
    }

    // Subtle dark vignette for crisp text/border separation
    final vignettePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.24),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    if (brightness < 0.99) {
      canvas.drawRect(
        rect,
        Paint()..color = Colors.black.withValues(alpha: (1.0 - brightness).clamp(0.0, 0.6)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GeneratedArtPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.brightness != brightness;
  }
}
