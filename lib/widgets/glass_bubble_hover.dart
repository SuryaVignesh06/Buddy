import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';

/// Hover / long-press mini glass bubble for inactive nav destinations.
/// Scales to 1.12 with 8% white fill, rim light, pointer-tracked specular parallax, and floating label.
class GlassBubbleHover extends StatelessWidget {
  const GlassBubbleHover({
    super.key,
    required this.label,
    required this.visible,
    required this.parallax,
    required this.child,
  });

  final String label;
  final bool visible;
  final Offset parallax; // clamped -6..6 px
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clampedOffset = Offset(
      parallax.dx.clamp(-6.0, 6.0),
      parallax.dy.clamp(-6.0, 6.0),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Floating label tooltip above the bubble
        Positioned(
          top: -34,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: visible ? 1.0 : 0.0,
              duration: OrbitTokens.durPress,
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, 0.2),
                duration: OrbitTokens.durChip,
                curve: OrbitTokens.curveDefault,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: OrbitTokens.surface2.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(OrbitTokens.radiusChip),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: OrbitTypography.nav.copyWith(
                      color: OrbitTokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Mini glass bubble around the icon
        AnimatedScale(
          scale: visible ? 1.12 : 1.0,
          duration: OrbitTokens.durChip,
          curve: OrbitTokens.curveDefault,
          child: AnimatedContainer(
            duration: OrbitTokens.durPress,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: visible ? OrbitTokens.glassTint : Colors.transparent,
              border: visible
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.0,
                    )
                  : null,
              gradient: visible
                  ? RadialGradient(
                      center: Alignment(
                        clampedOffset.dx / 12.0,
                        clampedOffset.dy / 12.0 - 0.35,
                      ),
                      radius: 0.9,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                    )
                  : null,
            ),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}
