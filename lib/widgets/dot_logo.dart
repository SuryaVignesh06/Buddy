import 'package:flutter/material.dart';

import '../features/splash/dot_painter.dart';

/// Reusable mascot logo widget ("Dot").
class DotLogo extends StatelessWidget {
  const DotLogo({
    super.key,
    this.size = 36.0,
    this.headphones = false,
    this.blink = 0.0,
    this.squash = 0.0,
    this.eyeLook = 0.0,
    this.beatPulse = 0.0,
    this.happyEyes = 0.0,
    this.headphoneOpacity = 1.0,
  });

  final double size;
  final bool headphones;
  final double blink;
  final double squash;
  final double eyeLook;
  final double beatPulse;
  final double happyEyes;
  final double headphoneOpacity;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: DotPainter(
            headphones: headphones,
            blink: blink,
            squash: squash,
            eyeLook: eyeLook,
            beatPulse: beatPulse,
            happyEyes: happyEyes,
            headphoneOpacity: headphoneOpacity,
          ),
        ),
      ),
    );
  }
}
