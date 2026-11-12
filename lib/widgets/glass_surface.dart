import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/orbit_state.dart';
import '../core/springs.dart';
import '../core/tokens.dart';

/// Tier B liquid-glass surface (no BackdropFilter).
/// Combines diagonal translucent fill, 1 px corner-bright rim, 40% top specular,
/// 30% warm flame inner glow, soft elevation shadow, scroll-parallax rim shift,
/// and spring lift (+4 px & 80% rim) on desktop hover or touch hold.
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 16.0,
    this.intensity = 1.0,
    this.tint,
    this.padding,
    this.onTap,
    this.enableHoverLift = true,
    this.circular = false,
    this.scrollOffset,
    this.height,
    this.width,
    this.rimBrightBoost = 0.0,
  });

  final Widget child;
  final double radius;
  final double intensity;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool enableHoverLift;
  final bool circular;
  final ValueListenable<double>? scrollOffset;
  final double? height;
  final double? width;
  final double rimBrightBoost;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _liftController;
  bool _hovered = false;
  bool _held = false;
  ValueListenable<double>? _resolvedScroll;

  @override
  void initState() {
    super.initState();
    _liftController = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvedScroll = widget.scrollOffset ?? OrbitScope.maybeOf(context)?.scrollOffset;
  }

  @override
  void didUpdateWidget(covariant GlassSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollOffset != widget.scrollOffset) {
      _resolvedScroll = widget.scrollOffset ?? OrbitScope.maybeOf(context)?.scrollOffset;
    }
  }

  void _updateInteraction({bool? hovered, bool? held}) {
    if (!widget.enableHoverLift) return;
    final nextHover = hovered ?? _hovered;
    final nextHeld = held ?? _held;
    final wasActive = _hovered || _held;
    final isActive = nextHover || nextHeld;
    _hovered = nextHover;
    _held = nextHeld;
    if (wasActive == isActive) return;

    final target = isActive ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _liftController.value = target;
    } else {
      _liftController.animateWith(
        Springs.simulate(
          Springs.liquid,
          start: _liftController.value,
          end: target,
        ),
      );
    }
  }

  @override
  void dispose() {
    _liftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      widget.circular ? 999.0 : widget.radius,
    );

    final repaint = _resolvedScroll != null
        ? Listenable.merge([_liftController, _resolvedScroll!])
        : _liftController;

    Widget surface = AnimatedBuilder(
      animation: repaint,
      child: widget.padding != null
          ? Padding(padding: widget.padding!, child: widget.child)
          : widget.child,
      builder: (context, child) {
        final lift = _liftController.value;
        final scroll = _resolvedScroll?.value ?? 0.0;
        final shift = (scroll * 0.0008).clamp(-0.45, 0.45);
        final rimBoost = (lift.clamp(0.0, 1.2) * 0.25 + widget.rimBrightBoost)
            .clamp(0.0, 0.35);

        return Transform.translate(
          offset: Offset(0, -4.0 * lift),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000), // black 35%
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: CustomPaint(
                painter: _GlassSurfacePainter(
                  radius: widget.circular ? 999.0 : widget.radius,
                  circular: widget.circular,
                  intensity: widget.intensity.clamp(0.2, 1.5),
                  tint: widget.tint,
                  shift: shift,
                  rimBoost: rimBoost,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );

    if (widget.enableHoverLift) {
      surface = MouseRegion(
        onEnter: (_) => _updateInteraction(hovered: true),
        onExit: (_) => _updateInteraction(hovered: false),
        child: Listener(
          onPointerDown: (_) => _updateInteraction(held: true),
          onPointerUp: (_) => _updateInteraction(held: false),
          onPointerCancel: (_) => _updateInteraction(held: false),
          child: surface,
        ),
      );
    }

    if (widget.onTap != null) {
      surface = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: surface,
      );
    }

    return surface;
  }
}

class _GlassSurfacePainter extends CustomPainter {
  _GlassSurfacePainter({
    required this.radius,
    required this.circular,
    required this.intensity,
    required this.tint,
    required this.shift,
    required this.rimBoost,
  });

  final double radius;
  final bool circular;
  final double intensity;
  final Color? tint;
  final double shift;
  final double rimBoost;

  final Paint _fillPaint = Paint();
  final Paint _tintPaint = Paint();
  final Paint _specPaint = Paint();
  final Paint _glowPaint = Paint();
  final Paint _rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = circular ? size.shortestSide / 2 : radius;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // 1. Fill: linear gradient top-left -> bottom-right, white 16% -> 5%
    _fillPaint.shader = LinearGradient(
      begin: Alignment(-1.0 + shift, -1.0),
      end: Alignment(1.0 + shift, 1.0),
      colors: [
        Colors.white.withValues(alpha: (0.16 * intensity).clamp(0.0, 0.35)),
        Colors.white.withValues(alpha: (0.05 * intensity).clamp(0.0, 0.2)),
      ],
    ).createShader(rect);
    canvas.drawRRect(rrect, _fillPaint);

    if (tint != null) {
      _tintPaint.color = tint!.withValues(alpha: (0.14 * intensity).clamp(0.0, 0.35));
      canvas.drawRRect(rrect, _tintPaint);
    }

    // 3. Top specular: top 40%, white 14% -> 0
    final topRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.40);
    _specPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: (0.14 * intensity).clamp(0.0, 0.28)),
        Colors.transparent,
      ],
    ).createShader(topRect);
    canvas.drawRect(topRect, _specPaint);

    // 4. Inner glow: bottom 30%, flame 10% -> 0
    final bottomTop = size.height * 0.70;
    final bottomRect =
        Rect.fromLTWH(0, bottomTop, size.width, size.height * 0.30);
    _glowPaint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        (tint ?? OrbitTokens.flame).withValues(
          alpha: (0.10 * intensity).clamp(0.0, 0.25),
        ),
        Colors.transparent,
      ],
    ).createShader(bottomRect);
    canvas.drawRect(bottomRect, _glowPaint);

    // 2. Rim: 1 px gradient border, white 55% -> 6% -> 20% (brightens to 80% on hover/hold)
    final rimRect = rect.deflate(0.5);
    final rimRRect = RRect.fromRectAndRadius(rimRect, Radius.circular((r - 0.5).clamp(0, r)));
    final topAlpha = (0.55 + rimBoost).clamp(0.0, 0.80);
    final midAlpha = (0.06 + rimBoost * 0.25).clamp(0.0, 0.30);
    final botAlpha = (0.20 + rimBoost * 0.50).clamp(0.0, 0.80);
    _rimPaint.shader = LinearGradient(
      begin: Alignment(-1.0 + shift, -1.0),
      end: Alignment(1.0 + shift, 1.0),
      colors: [
        Colors.white.withValues(alpha: topAlpha),
        Colors.white.withValues(alpha: midAlpha),
        Colors.white.withValues(alpha: botAlpha),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);
    canvas.drawRRect(rimRRect, _rimPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassSurfacePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.circular != circular ||
        oldDelegate.intensity != intensity ||
        oldDelegate.tint != tint ||
        oldDelegate.shift != shift ||
        oldDelegate.rimBoost != rimBoost;
  }
}

/// 44 px circular Tier B glass icon button inside a >=48 px touch target.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = OrbitTokens.textPrimary,
    this.iconSize = 20.0,
    this.buttonSize = 44.0,
    this.touchSize = OrbitTokens.minTouchTarget,
    this.tint,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final double iconSize;
  final double buttonSize;
  final double touchSize;
  final Color? tint;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: touchSize,
          height: touchSize,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GlassSurface(
                  width: buttonSize,
                  height: buttonSize,
                  circular: true,
                  tint: tint,
                  intensity: 0.95,
                  child: Center(
                    child: Icon(icon, color: iconColor, size: iconSize),
                  ),
                ),
                if (badge)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: OrbitTokens.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: OrbitTokens.flameRed,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
