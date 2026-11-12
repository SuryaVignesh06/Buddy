import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// CustomPainter for "Dot", Orbit's glossy Grok-style orb mascot.
class DotPainter extends CustomPainter {
  const DotPainter({
    this.headphones = false,
    this.blink = 0.0,
    this.squash = 0.0,
    this.eyeLook = 0.0,
    this.beatPulse = 0.0,
    this.happyEyes = 0.0,
    this.headphoneOpacity = 1.0,
  });

  final bool headphones;
  final double blink; // 0 = open, 1 = closed (scaleY -> 0.1)
  final double squash; // 0 = circle, 1 = (1.18, 0.82) impact squash
  final double eyeLook; // -1..1 vertical look offset (+1 = looking down)
  final double beatPulse; // 0..1 ear cup beat pulse (1.0 -> 1.08)
  final double happyEyes; // 0..1 listening expression
  final double headphoneOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Leave breathing room around the orb when headphones are visible.
    final orbDiameter = headphones ? size.shortestSide * 0.78 : size.shortestSide;
    final radius = orbDiameter / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final sx = 1.0 + 0.18 * squash;
    final sy = 1.0 - 0.18 * squash;
    canvas.scale(sx, sy);

    // 1. Soft bottom drop shadow beneath the sphere
    final shadowRect = Rect.fromCenter(
      center: Offset(0, radius * 0.92),
      width: orbDiameter * 0.72,
      height: orbDiameter * 0.22,
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.22);
    canvas.drawOval(shadowRect, shadowPaint);

    // 2. Sphere body: white -> cool silver-blue rim radial gradient
    final orbRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.4, -0.4), // 30% / 30% top-left highlight
        radius: 1.05,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFE9EEF7),
          Color(0xFFC7D0E0),
        ],
        stops: [0.0, 0.58, 1.0],
      ).createShader(orbRect);
    canvas.drawCircle(Offset.zero, radius, bodyPaint);

    // Subtle bottom rim shading inside sphere for 3D depth
    final bottomShadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF9AA8C2).withValues(alpha: 0.22),
        ],
        stops: const [0.55, 1.0],
      ).createShader(orbRect);
    canvas.drawCircle(Offset.zero, radius, bottomShadePaint);

    // 3. Inner top specular ellipse at 35% white
    canvas.save();
    canvas.translate(-radius * 0.22, -radius * 0.42);
    canvas.rotate(-0.38);
    final specularRect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 0.76,
      height: radius * 0.34,
    );
    final specularPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(specularRect);
    canvas.drawOval(specularRect, specularPaint);
    canvas.restore();

    // 4. Two tilted pill eyes (-18 deg), apart by 22% of diameter
    _drawEyes(canvas, orbDiameter, radius);

    // 5. Headphones (splash and Now Playing only)
    if (headphones && headphoneOpacity > 0.01) {
      _drawHeadphones(canvas, orbDiameter, radius);
    }

    canvas.restore();
  }

  void _drawEyes(Canvas canvas, double diameter, double radius) {
    final eyeSeparation = diameter * 0.22;
    final eyeCenterY = -radius * 0.08 + eyeLook * radius * 0.26;
    final eyeCenterXShift = eyeLook * radius * 0.04;

    final baseWidth = diameter * 0.115;
    final baseHeight = diameter * (0.21 + 0.025 * happyEyes);
    final blinkScaleY = (1.0 - 0.9 * blink.clamp(0.0, 1.0)).clamp(0.1, 1.0);
    const tiltRad = -18.0 * math.pi / 180.0;

    for (final side in const [-1.0, 1.0]) {
      final ex = side * (eyeSeparation / 2) + eyeCenterXShift;
      final ey = eyeCenterY;

      canvas.save();
      canvas.translate(ex, ey);
      canvas.rotate(tiltRad);
      canvas.scale(1.0, blinkScaleY);

      if (happyEyes > 0.45 && blink < 0.3) {
        // Soften into a warm happy pill-arc while listening
        final happyBlend = ((happyEyes - 0.45) / 0.55).clamp(0.0, 1.0);
        final eyeRect = Rect.fromCenter(
          center: Offset.zero,
          width: baseWidth * (1.0 + 0.15 * happyBlend),
          height: baseHeight * (1.0 - 0.28 * happyBlend),
        );
        final eyePaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OrbitTokens.dotEyeTop, OrbitTokens.dotEyeBottom],
          ).createShader(eyeRect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(eyeRect, Radius.circular(baseWidth)),
          eyePaint,
        );
      } else {
        final eyeRect = Rect.fromCenter(
          center: Offset.zero,
          width: baseWidth,
          height: baseHeight,
        );
        final eyePaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OrbitTokens.dotEyeTop, OrbitTokens.dotEyeBottom],
          ).createShader(eyeRect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(eyeRect, Radius.circular(baseWidth)),
          eyePaint,
        );
      }

      // 2px crisp highlight dot on each eye
      if (blinkScaleY > 0.35) {
        final dotRadius = (diameter * 0.022).clamp(1.0, 2.4);
        final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
        canvas.drawCircle(
          Offset(-baseWidth * 0.18, -baseHeight * 0.24),
          dotRadius,
          dotPaint,
        );
      }

      canvas.restore();
    }
  }

  void _drawHeadphones(Canvas canvas, double diameter, double radius) {
    final alpha = headphoneOpacity.clamp(0.0, 1.0);
    final bandStroke = diameter * 0.08;
    final bandRadius = radius + bandStroke * 0.68;
    final bandRect = Rect.fromCircle(center: Offset.zero, radius: bandRadius);

    // 200 degree arc over the top (-190 deg -> +10 deg)
    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bandStroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          OrbitTokens.accent.withValues(alpha: alpha),
          OrbitTokens.amber.withValues(alpha: alpha),
          OrbitTokens.accentHot.withValues(alpha: alpha),
        ],
      ).createShader(bandRect);

    const startAngle = -190.0 * math.pi / 180.0;
    const sweepAngle = 200.0 * math.pi / 180.0;
    canvas.drawArc(bandRect, startAngle, sweepAngle, false, bandPaint);

    // Ear cups: rounded rectangles in surface1 with accent ring + amber inner glow
    final cupWidth = diameter * 0.20;
    final cupHeight = diameter * 0.40;
    final cupRadius = Radius.circular(cupWidth * 0.45);
    final cupScale = 1.0 + 0.08 * beatPulse.clamp(0.0, 1.0);

    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * (radius + cupWidth * 0.24), radius * 0.04);
      canvas.scale(cupScale, cupScale);

      final cupRect = Rect.fromCenter(
        center: Offset.zero,
        width: cupWidth,
        height: cupHeight,
      );
      final cupRRect = RRect.fromRectAndRadius(cupRect, cupRadius);

      // Amber inner/outer beat glow
      final glowPaint = Paint()
        ..color = OrbitTokens.amber.withValues(
          alpha: (0.28 + 0.35 * beatPulse) * alpha,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cupWidth * 0.45);
      canvas.drawRRect(cupRRect, glowPaint);

      // Surface1 body
      final cupBodyPaint = Paint()
        ..color = OrbitTokens.surface1.withValues(alpha: alpha);
      canvas.drawRRect(cupRRect, cupBodyPaint);

      // Accent ring stroke
      final cupRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (diameter * 0.03).clamp(1.2, 3.0)
        ..color = OrbitTokens.accent.withValues(alpha: alpha);
      canvas.drawRRect(cupRRect, cupRingPaint);

      // Small amber core indicator
      final coreRect = Rect.fromCenter(
        center: Offset.zero,
        width: cupWidth * 0.34,
        height: cupHeight * 0.44,
      );
      final corePaint = Paint()
        ..color = OrbitTokens.amber.withValues(
          alpha: (0.55 + 0.45 * beatPulse) * alpha,
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(coreRect, Radius.circular(cupWidth * 0.2)),
        corePaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant DotPainter oldDelegate) {
    return oldDelegate.headphones != headphones ||
        oldDelegate.blink != blink ||
        oldDelegate.squash != squash ||
        oldDelegate.eyeLook != eyeLook ||
        oldDelegate.beatPulse != beatPulse ||
        oldDelegate.happyEyes != happyEyes ||
        oldDelegate.headphoneOpacity != headphoneOpacity;
  }
}
