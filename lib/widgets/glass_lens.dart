import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Builds a smooth metaball path joining a leader rect and trailing follower rect
/// with cubic curves so the liquid-glass nav lens stretches and pulls together.
Path buildMetaballPath({
  required Rect leader,
  required Rect follower,
  required double radius,
}) {
  final dist = (leader.center.dx - follower.center.dx).abs();
  if (dist < 2.5) {
    final combined = leader.expandToInclude(follower);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(combined, Radius.circular(radius)));
  }

  final leftIsLeader = leader.center.dx < follower.center.dx;
  final leftRect = leftIsLeader ? leader : follower;
  final rightRect = leftIsLeader ? follower : leader;

  final path = Path()
    ..addRRect(RRect.fromRectAndRadius(leftRect, Radius.circular(radius)))
    ..addRRect(RRect.fromRectAndRadius(rightRect, Radius.circular(radius)));

  // Smooth cubic bridge waist between the two lobes
  final gap = (rightRect.center.dx - leftRect.center.dx).abs();
  final maxSpan = (leftRect.width + rightRect.width) * 1.4;
  if (gap < maxSpan) {
    final bridgeFactor = (1.0 - gap / maxSpan).clamp(0.15, 1.0);
    final midX = (leftRect.center.dx + rightRect.center.dx) / 2;
    final leftAnchorX = leftRect.center.dx + leftRect.width * 0.22;
    final rightAnchorX = rightRect.center.dx - rightRect.width * 0.22;
    final halfH = math.min(leftRect.height, rightRect.height) * 0.5;
    final waistInset = halfH * (0.42 * (1.0 - bridgeFactor));

    final topLeftY = leftRect.top + 1.5;
    final topRightY = rightRect.top + 1.5;
    final botLeftY = leftRect.bottom - 1.5;
    final botRightY = rightRect.bottom - 1.5;
    final topWaistY = (topLeftY + topRightY) / 2 + waistInset;
    final botWaistY = (botLeftY + botRightY) / 2 - waistInset;

    final bridge = Path()
      ..moveTo(leftAnchorX, topLeftY)
      ..cubicTo(
        midX,
        topWaistY,
        midX,
        topWaistY,
        rightAnchorX,
        topRightY,
      )
      ..lineTo(rightAnchorX, botRightY)
      ..cubicTo(
        midX,
        botWaistY,
        midX,
        botWaistY,
        leftAnchorX,
        botLeftY,
      )
      ..close();

    return Path.combine(PathOperation.union, path, bridge);
  }

  return path;
}

/// Tier A liquid-glass metaball lens for [FloatingGlassNav].
/// Clips [BackdropFilter], gradient fills, specular highlights, and swept rim
/// to the leader/follower metaball droplet path.
class GlassLens extends StatelessWidget {
  const GlassLens({
    super.key,
    required this.totalWidth,
    required this.height,
    required this.leaderRect,
    required this.followerRect,
    required this.childCenterX,
    required this.childWidth,
    required this.child,
    this.radius = 30.0,
    this.stretchX = 1.0,
    this.squashX = 1.0,
    this.specularOffset = Offset.zero,
    this.enableBackdropBlur = true,
  });

  final double totalWidth;
  final double height;
  final Rect leaderRect;
  final Rect followerRect;
  final double childCenterX;
  final double childWidth;
  final Widget child;
  final double radius;
  final double stretchX;
  final double squashX;
  final Offset specularOffset;
  final bool enableBackdropBlur;

  // Saturation 1.5 + brightness 1.05 colour matrix (Rec.709 luminance)
  static const List<double> liquidColorMatrix = <double>[
    1.4619, -0.3755, -0.0379, 0.0, 0.0,
    -0.1116, 1.1980, -0.0379, 0.0, 0.0,
    -0.1116, -0.3755, 1.5356, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveStretch = (stretchX * squashX).clamp(0.90, 1.30);
    final effectiveSquashY =
        (1.0 / math.sqrt(effectiveStretch)).clamp(0.86, 1.06);

    final stretchedLeader = Rect.fromCenter(
      center: leaderRect.center,
      width: leaderRect.width * effectiveStretch,
      height: leaderRect.height * effectiveSquashY,
    );
    final stretchedFollower = Rect.fromCenter(
      center: followerRect.center,
      width: followerRect.width * (0.86 + 0.14 * effectiveStretch),
      height: followerRect.height * (0.94 * effectiveSquashY),
    );

    final metaballPath = buildMetaballPath(
      leader: stretchedLeader,
      follower: stretchedFollower,
      radius: radius,
    );

    final clipper = _PathClipper(metaballPath);

    return SizedBox(
      width: totalWidth,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: clipper,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (enableBackdropBlur)
                  BackdropFilter(
                    filter: ImageFilter.compose(
                      outer: const ColorFilter.matrix(liquidColorMatrix),
                      inner: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    ),
                    child: const SizedBox.expand(),
                  )
                else
                  Container(
                    color: OrbitTokens.surface2.withValues(alpha: 0.78),
                  ),

                // Translucent vertical fill
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.11),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Warm flame bottom inner glow centered on leader
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        ((leaderRect.center.dx / totalWidth) * 2 - 1)
                            .clamp(-0.9, 0.9),
                        0.9,
                      ),
                      radius: 0.55,
                      colors: [
                        OrbitTokens.orange.withValues(alpha: 0.24),
                        OrbitTokens.flameRed.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Top specular glint strip over the leader lobe
                Positioned(
                  top: 3,
                  left: stretchedLeader.left + 12 + specularOffset.dx,
                  width: math.max(16.0, stretchedLeader.width - 24),
                  height: 6,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.58),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Metaball swept rim stroke
                IgnorePointer(
                  child: CustomPaint(
                    painter: _MetaballRimPainter(
                      path: metaballPath,
                      parallax: specularOffset,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active icon + label centered on leader
          Positioned(
            left: childCenterX - childWidth / 2,
            top: 0,
            width: childWidth,
            height: height,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _PathClipper oldClipper) => true;
}

class _MetaballRimPainter extends CustomPainter {
  const _MetaballRimPainter({
    required this.path,
    required this.parallax,
  });

  final Path path;
  final Offset parallax;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final alignment = Alignment(
      (parallax.dx * 0.04).clamp(-0.25, 0.25),
      (parallax.dy * 0.04).clamp(-0.25, 0.25),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..shader = SweepGradient(
        center: alignment,
        colors: const [
          OrbitTokens.glassRimEnd,
          OrbitTokens.glassRimStart,
          OrbitTokens.glassRimMid,
          OrbitTokens.glassRimStart,
          OrbitTokens.glassRimEnd,
        ],
        stops: const [0.0, 0.14, 0.44, 0.68, 1.0],
      ).createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MetaballRimPainter oldDelegate) => true;
}
